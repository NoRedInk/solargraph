module Solargraph
  module Pin
    class Method < Base
      attr_reader :scope
      attr_reader :visibility
      attr_reader :parameters

      def initialize location, namespace, name, docstring, scope, visibility, args
        super(location, namespace, name, docstring)
        @scope = scope
        @visibility = visibility
        @parameters = args
      #   super(source, node, namespace)
      #   @scope = scope
      #   @visibility = visibility
      #   # Exception for initialize methods
      #   if name == 'initialize' and scope == :instance
      #     @visibility = :private
      #   end
      #   @fully_resolved = false
      end

      def kind
        Solargraph::Pin::METHOD
      end

      def path
        @path ||= namespace + (scope == :instance ? '#' : '.') + name
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::METHOD
      end

      def return_type
        if @return_type.nil? and !docstring.nil?
          tag = docstring.tag(:return)
          if tag.nil?
            ol = docstring.tag(:overload)
            tag = ol.tag(:return) unless ol.nil?
          end
          @return_type = tag.types[0] unless tag.nil? or tag.types.nil?
        end
        @return_type
      end

      def documentation
        if @documentation.nil?
          @documentation ||= super || ''
          unless docstring.nil?
            param_tags = docstring.tags(:param)
            unless param_tags.nil? or param_tags.empty?
              @documentation += "\n\n"
              @documentation += "Params:\n"
              lines = []
              param_tags.each do |p|
                l = "* #{p.name}"
                l += " [#{p.types.join(', ')}]" unless p.types.empty?
                l += " #{p.text}"
                lines.push l
              end
              @documentation += lines.join("\n")
            end
          end
        end
        @documentation
      end

      # @todo This method was temporarily migrated directly from Suggestion
      # @return [Array<String>]
      def params
        if @params.nil?
          @params = []
          return @params if docstring.nil?
          param_tags = docstring.tags(:param)
          unless param_tags.empty?
            param_tags.each do |t|
              txt = t.name.to_s
              txt += " [#{t.types.join(',')}]" unless t.types.nil? or t.types.empty?
              txt += " #{t.text}" unless t.text.nil? or t.text.empty?
              @params.push txt
            end
          end
        end
        @params
      end

      def resolve api_map
        if return_type.nil?
          sc = api_map.superclass_of(namespace)
          until sc.nil?
            sc_path = "#{sc}#{scope == :instance ? '#' : '.'}#{name}"
            sugg = api_map.get_path_suggestions(sc_path).first
            break if sugg.nil?
            @return_type = api_map.find_fully_qualified_namespace(sugg.return_type, sugg.namespace) unless sugg.return_type.nil?
            break unless @return_type.nil?
            sc = api_map.superclass_of(sc)
          end
        end
        unless return_type.nil? or @fully_resolved
          @fully_resolved = true
          @return_type = api_map.find_fully_qualified_namespace(@return_type, namespace)
        end
      end

      def method?
        true
      end
    end
  end
end
