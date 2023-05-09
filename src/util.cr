module Kaze
  # Utility functions.
  module Util
    extend self

    # Remove extra backslash to un-escape characters.
    def remove_escape_seqs(str : String) : String
      escape_seqs = ['n', 't']
      escaped_chars = ["\n", "\t"]

      str.gsub(/\\([#{escape_seqs.join}])/) do |match|
        char_idx = escape_seqs.index(match[1])
        char_idx ? escaped_chars[char_idx] : match
      end
    end

    # Stringifies an expression value.
    def stringify(object : VG)
      return "nil" if object == nil
      text = object.to_s

      if object.is_a?(Float64)
        if text.ends_with?(".0")
          text = text[0...(text.size - 2)]
        end

        return text
      end

      # Replace escape sequences.
      Util.remove_escape_seqs(text)
    end

    # A stack data structure.
    # Used by the resolver.
    class Stack(T)
      private property elements : Array(T)

      def initialize
        @elements = Array(T).new
      end

      def push(elem : T)
        @elements.push(elem)
      end

      def pop
        @elements.pop
      end

      def peek
        @elements.last
      end

      def size
        @elements.size
      end

      def empty?
        @elements.empty?
      end

      def [](i : Int32)
        @elements[i]
      end

      def to_s
        @elements
      end
    end
  end
end
