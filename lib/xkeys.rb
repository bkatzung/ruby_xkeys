# XKeys - Extended keys to facilitate fetching and storing in nested
#	hash and array structures with Perl-ish auto-vivification.
#
# Synopsis:
#  root = {}.extend XKeys::Hash
#  root = [].extend XKeys::Auto
#
# Author:: Brian Katzung <briank@kappacs.com>, Kappa Computer Solutions, LLC
# Copyright:: 2013 Brian Katzung and Kappa Computer Solutions, LLC
# License:: MIT License

module XKeys; end

# Extended fetch and get ([])
module XKeys::Get

    # Perform an extended fetch using successive keys to traverse a tree
    # of nested hashes and/or arrays.
    #
    #   xfetch([nil,] key1, ..., keyN [, :else => default_value])
    #
    #   An optional leading nil key is ignored (see []). If the specified
    #   keys do not exist, the default value is returned (if provided) or
    #   the standard exception (e.g. KeyError or IndexError) is raised.
    def xfetch (*args)
	if args[-1].is_a?(Hash) then options, last = args[-1], -2
	else options, last = {}, -1
	end
	first = (args[0] == nil) ? 1 : 0
	args[first..last].inject(self) do |node, key|
	    begin node.fetch key
	    rescue KeyError, IndexError
		return options[:else] if options.has_key? :else
		raise
	    end
	end
    end

    # Perform an extended get using successive keys to traverse a tree of
    # nested hashes and/or arrays.
    #
    #   [key] returns the hash or array element (or range-based array slice)
    #   as normal.
    #
    #   array[int1, int2] returns a length-based array slice as normal.
    #   Prepend a nil key and/or append an option hash to force nested index
    #   behavior for two integer array indexes: array[nil, index1, index2].
    #
    #   [[nil,] key1, ..., keyN[, option_hash]] traverses a tree of nested
    #   hashes and/or arrays using xfetch. The optional leading nil key is
    #   always ignored. In the absence of an option hash, the default is
    #   :else => nil.
    def [] (*args)
	if args.count == 1 || (self.is_a?(Array) && args.count == 2 &&
	  args[0].is_a?(Integer) && args[1].is_a?(Integer))
	    # [key] or array[start, length]
	    super *args
	elsif args[-1].is_a?(Hash) then xfetch(*args)
	else xfetch(*args, :else => nil)
	end
    end

end

# "Private" module for XKeys::Set_* common code
module XKeys::Set_

    # Common code for XKeys::Set_Hash and XKeys::Set_Auto
    def _xset (*args)
	if args.count == 2
	    if self.is_a?(Array) && args[0] == nil
		self << args[1]		# array[nil] = value
	    else return false		# [key] = value ==> super *args
	    end
	else
	    # root[key1, ..., keyN] = value
	    (node, key) = args[1..-2].inject([self, args[0]]) do |node, key|
		if yield key
		    node[0][node[1]] ||= []
		    [node[0][node[1]], key || node[0][node[1]].size]
		else
		    node[0][node[1]] ||= {}
		    [node[0][node[1]], key]
		end
	    end
	    if yield key then node[key || node.size] = args[-1]
	    else node[key] = args[-1]
	    end
	end
	true
    end

end

# Extended set ([]=) with hash keys
module XKeys::Set_Hash
    include XKeys::Set_

    # Auto-vivify nested hash trees using extended hash key/array index
    # assignment syntax. Nil keys create nested arrays as needed. Other
    # keys, including integer keys, create nested hashes as needed.
    #
    #   root[key1, ..., keyN] = value
    def []= (*args)
	super *args unless _xset(*args) { |key| key == nil }
	args[-1]
    end

end

# Extended set ([]=) with automatic selection of hash keys or array indexes
module XKeys::Set_Auto
    include XKeys::Set_

    # Auto-vivify nested hash and/or array trees using extended hash
    # key/array index assignment syntax. Nil keys and integer keys
    # created nested arrays as needed. Other keys create nested hashes
    # as needed.
    #
    #   root[key1, ..., keyN] = value
    def []= (*args)
	super *args unless
	  _xset(*args) { |key| key == nil || key.is_a?(Integer) }
	args[-1]
    end

end

# Combined interfaces

# XKeys::Hash combines XKeys::Get and XKeys::Set_Hash
module XKeys::Hash; include XKeys::Get; include XKeys::Set_Hash; end

# XKeys::Auto combines XKeys::Get and XKeys::Set_Auto
module XKeys::Auto; include XKeys::Get; include XKeys::Set_Auto; end

# END
