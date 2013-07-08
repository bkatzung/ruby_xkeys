# XKeys - Extended keys to facilitate fetching and storing in nested
#	hash and array structures with Perl-ish auto-vivification.
#
# Author:: Brian Katzung <briank@kappacs.com>, Kappa Computer Solutions, LLC
# Copyright:: 2013 Brian Katzung and Kappa Computer Solutions, LLC
# License:: MIT License

module XKeys; end

# Extended fetch and get ([]) interfaces
module XKeys::Get

    # Perform an extended fetch using successive keys to traverse a tree
    # of nested hashes and/or arrays.
    #
    # xfetch([nil,] key1, ..., keyN [, :else => default_value])
    #
    # An optional leading nil key is ignored (see []). If the specified
    # keys do not exist, the default value is returned (if provided) or
    # the standard exception (e.g. KeyError or IndexError) is raised.
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
    # [key] returns the hash or array element (or range-based array slice)
    # as normal.
    #
    # array[int1, int2] returns a length-based array slice as normal.
    # Prepend a nil key and/or append an option hash to force nested index
    # behavior for two integer array indexes: array[nil, index1, index2].
    #
    # [[nil,] key1, ..., keyN[, option_hash]] traverses a tree of nested
    # hashes and/or arrays using xfetch. The optional leading nil key is
    # always ignored. In the absence of an option hash, the default is
    # :else => nil.
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

# Extended set ([]=) hash keys interface
# (nil keys auto-vivify arrays but integer keys auto-vivify hashes)
module XKeys::Set_Hash

    # Auto-vivify nested hash trees using extended hash key/array index
    # assignment syntax.
    def []= (*args)
	if args.count == 2
	    if self.is_a?(Array) && args[0] == nil
		self << args[1]		# array[nil] = value
	    else super *args		# [key] = value
	    end
	else
	    # tree[key1, ..., keyN] = value
	    (node, key) = args[1..-2].inject([self, args[0]]) do |node, key|
		if key == nil
		    node[0][node[1]] ||= []
		    [node[0][node[1]], node[0][node[1]].count]
		else
		    node[0][node[1]] ||= {}
		    [node[0][node[1]], key]
		end
	    end
	    if key == nil then node << args[-1]
	    else node[key] = args[-1]
	    end
	end
	args[-1]
    end

end

# Extended set ([]=) hash keys or array indexes interface
# (nil keys and integer keys auto-vivify arrays)
module XKeys::Set_Auto

    # Auto-vivify nested hash and/or array trees using extended hash
    # key/array index assignment syntax.
    def []= (*args)
	if args.count == 2
	    if self.is_a?(Array) && args[0] == nil
		self << args[1]		# array[nil] = value
	    else super *args		# [key] = value
	    end
	else
	    # tree[key1, ..., keyN] = value syntax
	    # (method call []=(key1, ..., keyN, value))
	    (node, key) = args[1..-2].inject([self, args[0]]) do |node, key|
		if key == nil || key.is_a?(Integer)
		    node[0][node[1]] ||= []
		    [node[0][node[1]], key || node[0][node[1]].count]
		else
		    node[0][node[1]] ||= {}
		    [node[0][node[1]], key]
		end
	    end
	    if key == nil || key.is_a?(Integer)
		node[key || node.count] = args[-1]
	    else node[key] = args[-1]
	    end
	    args[-1]
	end
    end

end

# Combined interfaces

module XKeys::Hash; include XKeys::Get; include XKeys::Set_Hash; end

module XKeys::Auto; include XKeys::Get; include XKeys::Set_Auto; end

# END
