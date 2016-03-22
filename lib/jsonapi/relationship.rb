module JSONAPI
  class Relationship
    attr_reader :acts_as_set, :foreign_key, :type, :options, :name,
                :class_name, :polymorphic, :always_include_linkage_data,
                :parent_resource, :namespace_hint, :route_namespace

    def initialize(name, options = {})
      @name = name.to_s
      @options = options
      @acts_as_set = options.fetch(:acts_as_set, false) == true
      @foreign_key = options[:foreign_key] ? options[:foreign_key].to_sym : nil
      @parent_resource = options[:parent_resource]
      @relation_name = options.fetch(:relation_name, @name)
      @polymorphic = options.fetch(:polymorphic, false) == true
      @always_include_linkage_data = options.fetch(:always_include_linkage_data, false) == true
      @route_namespace = @parent_resource._route_hints
      @namespace_hint = options[:namespace_hint] ? options[:namespace_hint].to_sym : nil
    end

    alias_method :polymorphic?, :polymorphic

    def primary_key
      @primary_key ||= resource_klass._primary_key
    end

    def resource_klass
      @resource_klass = @parent_resource.resource_for(@class_name)
    end

    def relation_for_type(name, class_name, options)
      #if options has classname and does not equal the object.name then
      #then parse from class name.
      binding.pry
      if class_name == name
        class_name
      else
        if options.has_key?(:class_name) && options.has_key?(:parent_resource)
          class_array = class_name.downcase.split('::')
          parent_array = options[:parent_resource].to_s.downcase.split('::')
          parent_array.each do |item|
            if class_array.include?(item)
              class_array.delete(item)
            end
          end
          if class_array.empty?
            'UNKONWN RELATION TYPE 48'
          else
            class_array.map(&:singularize).join('_')
          end
        else
          'UNKONWN RELATION TYPE 53'
        end
      end
    end

    def relation_name(options)
      case @relation_name
        when Symbol
          # :nocov:
          @relation_name
          # :nocov:
        when String
          @relation_name.to_sym
        when Proc
          @relation_name.call(options)
      end
    end

    def type_for_source(source)
      if polymorphic?
        resource = source.public_send(name)
        resource.class._type_from_class if resource
      else
        type
      end
    end

    def relation_relation_name(name, options)
      if @namespace_hint.blank? || options.has_key?(:relation_name)
        options.fetch(:relation_name, name)
      else
        if name.to_s.downcase[@namespace_hint.to_s.downcase.pluralize] || name.to_s.downcase[@namespace_hint.to_s.downcase.singularize]
          relation_name = name
        else
          relation_name = @namespace_hint.to_s.downcase.singularize + '_' + name.to_s
        end
        relation_name.to_sym
      end
    end

    def relation_class_name(name, options)
      #if class_name is specified and a route_namespace is as well then
      #the class name must contraint the route_namespace. if it does not then
      #somebody built the wrong class_name and we need to rebuild better
      #faster and stronger.

      namespace_hint = options[:namespace_hint] ? options[:namespace_hint].to_sym : nil

      if  options.has_key?(:class_name) && !self.route_namespace.blank? && options[:class_name].to_s[self.route_namespace]
        options[:class_name]
      elsif !options.has_key?(:class_name) && self.route_namespace.blank? && namespace_hint.blank?
        name.to_s.camelize
      else
        class_path = self.route_namespace if !self.route_namespace.blank?

        if namespace_hint.blank?
          if self.route_namespace.blank?
            '::' + name.to_s.camelize
          else
            class_path + '::' + name.to_s.camelize
          end
        else
          class_path = class_path + '::' + namespace_hint.to_s.demodulize.classify.pluralize
          if namespace_hint == name || namespace_hint.to_s == name.to_s.pluralize
            class_path #zjsonbsS
          elsif name.to_s.downcase[namespace_hint.to_s.downcase.pluralize]
            class_path + '::' + name.to_s.sub(namespace_hint.to_s.pluralize + '_' , '').camelize
          elsif  name.to_s.downcase[namespace_hint.to_s.downcase.singularize]
            class_path + '::' + name.to_s.sub(namespace_hint.to_s.singularize + '_', '').camelize
          else
            class_path + '::' + name.to_s.camelize
          end
        end
      end
    end

    class ToOne < Relationship
      attr_reader :foreign_key_on

      def initialize(name, options = {})
        super
        @class_name = relation_class_name(name, options)
        @relation_name = relation_relation_name(name,options)
        @type = @relation_name.to_s.pluralize.to_sym
        @foreign_key ||= "#{relation_name(String)}_guid".to_sym
        @foreign_key_on = options.fetch(:foreign_key_on, :self)

      end

      def belongs_to?
        foreign_key_on == :self
      end

      def polymorphic_type
        "#{type.to_s.singularize}_type" if polymorphic?
      end
    end

    class ToMany < Relationship
      def initialize(name, options = {})

        super
        @class_name = relation_class_name(name, options).singularize
        @relation_name = relation_relation_name(name,options)
        @type = @relation_name.to_s.pluralize.to_sym
        @foreign_key ||= "#{relation_name(String).to_s.singularize}_guids".to_sym
      end
    end
  end
end
