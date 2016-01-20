module JSONAPI
  class Relationship
    attr_reader :acts_as_set, :foreign_key, :type, :options, :name,
                :class_name, :polymorphic, :always_include_linkage_data,
                :parent_resource

    def initialize(name, options = {})
      @name = name.to_s
      @options = options
      @acts_as_set = options.fetch(:acts_as_set, false) == true
      @foreign_key = options[:foreign_key] ? options[:foreign_key].to_sym : nil
      @parent_resource = options[:parent_resource]
      @relation_name = options.fetch(:relation_name, @name)
      @polymorphic = options.fetch(:polymorphic, false) == true
      @always_include_linkage_data = options.fetch(:always_include_linkage_data, false) == true
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
      if class_name == name
        class_name
      else
          #   zjsonb_publishers
          # {:class_name=>"Api::V1::Zjsonbs::Publisher", :parent_resource=>Api::V1::Zjsonas::BookResource}

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
            class_array.join('_')
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
        resource.class._type if resource
      else
        type
      end
    end

    class ToOne < Relationship
      attr_reader :foreign_key_on

      def initialize(name, options = {})
        super

        @class_name = options.fetch(:class_name, name.to_s.camelize)
        #puts "ToOne: #{class_name.underscore.pluralize.to_sym} name #{name}"
        #puts "ToOne: #{class_name.underscore.pluralize.to_sym}"
        binding.pry if "#{class_name.underscore.pluralize.to_sym}" == 'api/v1/zjsonbs/publishers'
        #myname = "#{class_name.to_s.underscore.singularize}_resource".camelize
        @type = relation_for_type(name.to_s.camelize, @class_name, options).underscore.pluralize.to_sym
        @foreign_key ||= "#{name}_guid".to_sym
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
        @class_name = options.fetch(:class_name, name.to_s.camelize.singularize)
        #puts "ToMany: #{class_name.underscore.pluralize.to_sym} name #{name}"
        @type = relation_for_type(name.to_s.camelize.singularize, @class_name, options).underscore.pluralize.to_sym
        #@type = class_name.underscore.pluralize.to_sym
        @foreign_key ||= "#{name.to_s.singularize}_guids".to_sym
      end
    end
  end
end
