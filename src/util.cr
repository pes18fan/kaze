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
  end
end