# frozen_string_literal: true

module Liquid
  # Templates are central to liquid.
  # Interpreting templates is a two step process. First you compile the source code you got.
  # During compiling, some extensive error checking is performed.
  #
  # After you have a compiled template you can `render` it.
  # You can render a compiled template over and over again and keep it cached.
  #
  # Example:
  #
  #   template = Liquid::Template.parse(source)
  #   template.render('user_name' => 'bob')
  #
  class Template
    attr_accessor :root
    attr_reader :resource_limits, :warnings, :profiler

    class TagRegistry
      include Enumerable

      def initialize
        @tags = {}
        @cache = {}
      end

      def [](tag_name)
        return nil unless @tags.key?(tag_name)
        return @cache[tag_name] if Liquid.cache_classes

        Object.const_get(@tags[tag_name]).tap { |o| @cache[tag_name] = o }
      end

      def []=(tag_name, klass)
        @tags[tag_name]  = klass.name
        @cache[tag_name] = klass
      end

      def delete(tag_name)
        @tags.delete(tag_name)
        @cache.delete(tag_name)
      end

      def each(&block)
        @tags.each(&block)
      end
    end

    class << self
      # Sets how strict the parser should be.
      #    `:lax` is the default, and silently ignores malformed tags in most cases.
      #   `:warn` will give deprecation warnings when invalid syntax is used.
      # `:strict` will enforce correct syntax.
      attr_writer :error_mode

      # Sets how strict the taint checker should be.
      #   `:lax` is the default, and ignores the taint flag completely.
      #  `:warn` adds a warning, but does not interrupt the rendering.
      # `:error` raises an error when tainted output is used.
      attr_writer :taint_mode

      attr_accessor :default_exception_renderer

      Template.default_exception_renderer = lambda do |exception|
        exception
      end

      def register_tag(name, klass)
        tags[name.to_s] = klass
      end

      def tags
        @tags ||= TagRegistry.new
      end

      def error_mode
        @error_mode ||= :lax
      end

      def taint_mode
        @taint_mode ||= :lax
      end

      # Pass a module with filter methods which should be available to all liquid views. Good for
      # registering the standard library.
      def register_filter(mod)
        Strainer.global_filter(mod)
      end

      def default_resource_limits
        @default_resource_limits ||= {}
      end

      # Creates a new `Template` object from liquid source code.
      # To enable profiling, pass in `profile: true` as an option.
      # See Liquid::Profiler for more information
      def parse(source, options = {})
        Template.new.parse(source, options)
      end
    end

    def initialize
      @rethrow_errors  = false
      @resource_limits = ResourceLimits.new(self.class.default_resource_limits)
    end

    # Parse source code.
    # Returns self for easy chaining.
    def parse(source, options = {})
      @options = options
      @profiling = options[:profile]
      @line_numbers = options[:line_numbers] || @profiling

      parse_context = options.is_a?(ParseContext) ? options : ParseContext.new(options)

      @root = Document.parse(tokenize(source), parse_context)
      @warnings = parse_context.warnings

      self
    end

    def registers
      @registers ||= {}
    end

    def assigns
      @assigns ||= {}
    end

    def instance_assigns
      @instance_assigns ||= {}
    end

    def errors
      @errors ||= []
    end

    # Render takes a hash with local variables.
    #
    # if you use the same filters over and over again consider registering them globally with
    # `Template.register_filter`.
    #
    # if profiling was enabled in `Template#parse` then the resulting profiling information will
    # be available via `Template#profiler`.
    #
    # Following options can be passed:
    #
    #  * `filters`   : array with local filters.
    #  * `registers` : hash with register variables. Those can be accessed from templates.
    #
    def render(*args)
      return '' if @root.nil?

      context = make_context(args.shift)

      case args.last
      when Hash
        options = args.pop

        given_registers = options[:registers]
        registers.merge!(given_registers) if given_registers.is_a?(Hash)

        apply_options_to_context(context, options)
      when Module, Array
        context.add_filters(args.pop)
      end

      # Retrying a render resets resource usage
      context.resource_limits.reset

      begin
        # Render the nodelist.
        # For performance reasons we get an array back here. `:join` will make a string out of it.
        result = @profiling ? render_with_profiler(context) : @root.render(context)
        result.respond_to?(:join) ? result.join : result
      rescue Liquid::MemoryError => e
        context.handle_error(e)
      ensure
        @errors = context.errors
      end
    end

    def render!(*args)
      @rethrow_errors = true
      render(*args)
    end

    private

    def tokenize(source)
      Tokenizer.new(source, @line_numbers)
    end

    def make_context(obj)
      case obj
      when Liquid::Context
        obj.exception_renderer = Liquid::RAISE_EXCEPTION_LAMBDA if @rethrow_errors
        obj
      when Liquid::Drop
        new_context([obj, assigns]).tap { |context| obj.context = context }
      when Hash
        new_context([obj, assigns])
      when nil
        new_context(assigns)
      else
        raise ArgumentError, "Expected Hash or Liquid::Context as parameter"
      end
    end

    def new_context(environments)
      Context.new(environments, instance_assigns, registers, @rethrow_errors, @resource_limits)
    end

    def render_with_profiler(context)
      return if context.partial
      raise "Profiler not loaded, require 'liquid/profiler' first" unless defined?(Liquid::Profiler)

      @profiler = Profiler.new.tap(&:start)

      begin
        @root.render(context)
      ensure
        @profiler.stop
      end
    end

    def apply_options_to_context(context, options)
      context.add_filters(options[:filters]) if options[:filters]

      context.global_filter      = options[:global_filter]      if options[:global_filter]
      context.exception_renderer = options[:exception_renderer] if options[:exception_renderer]
      context.strict_variables   = options[:strict_variables]   if options[:strict_variables]
      context.strict_filters     = options[:strict_filters]     if options[:strict_filters]
    end
  end
end
