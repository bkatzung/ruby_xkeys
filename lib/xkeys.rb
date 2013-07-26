# XKeys - Extended keys to facilitate fetching and storing in nested
#	hash and array structures with Perl-ish auto-vivification.
#
# Synopsis:
#  root = {}.extend XKeys::Hash
#  root[:my, :list, :[]] = 'value 1'
#  root[:my, :list, :[]] = 'value 2'
#  root[:sparse, 10] = 'value 3'
#  # => { :my => { :list => [ 'value 1', 'value 2' ] },
#  #    :sparse => { 10 => 'value 3' } }
#  root[:missing] # => nil
#  root[:missing, :else => false] # => false
#  root[:missing, :raise => true] # => raises KeyError
#
#  root = [].extend XKeys::Auto
#  root[1, :[]] = 'value 1'
#  root[1, 3] = 'value 2'
#  # => [ nil, [ 'value 1', nil, nil, 'value 2' ] ]
#  root[0, 1] # => [ nil ] (slice of length 1 at 0)
#  root[1, 0, {}] # => 'value 1'
#  root[1, 4, {}] # => nil
#
# @author Brian Katzung <briank@kappacs.com>, Kappa Computer Solutions, LLC
# @copyright 2013 Brian Katzung and Kappa Computer Solutions, LLC
# @license MIT License

module XKeys; end

# Extended fetch and get ([])
module XKeys::Get

    # Perform an extended fetch using successive keys to traverse a tree
    # of nested hashes and/or arrays.
    #
    #   xfetch(key1, ..., keyN [, option_hash])
    #
    #   Options:
    #
    #   :else => default value
    #       The default value to return if the specified keys do not exist.
    #       The :raise option takes precedence.
    #
    #   :raise => true
    #       Raise a KeyError or IndexError if the specified keys do not
    #       exist. This is the default behavior for xfetch in the absence
    #       of an :else option.
    #
    #   :raise => *parameters
    #       Like :raise => true but does raise *parameters instead, e.g.
    #       :raise => RuntimeError or :raise => [RuntimeError, 'SNAFU']
    def xfetch (*args)
	if args[-1].is_a?(Hash) then options, last = args[-1], -2
	else options, last = {}, -1
	end
	args[0..last].inject(self) do |node, key|
	    begin node.fetch key
	    rescue KeyError, IndexError
		if options[:raise] and options[:raise] != true
		    raise *options[:raise]
		elsif options[:raise] or !options.has_key? :else
		    raise
		else return options[:else]
		end
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
    #   Append an option hash to force nested index behavior for two
    #   integer array indexes: array[index1, index2, {}].
    #
    #   [key1, ..., keyN[, option_hash]] traverses a tree of nested
    #   hashes and/or arrays using xfetch.
    #
    #   Option :else => nil is used if no :else option is supplied.
    #   See xfetch for option details.
    def [] (*args)
	if args.count == 1 or (self.is_a?(Array) and args.count == 2 and
	  args[0].is_a?(Integer) and args[1].is_a?(Integer))
	    # [key] or array[start, length]
	    super *args
	else
	    def_opts = { :else => nil } # Default options
	    if args[-1].is_a? Hash
		options, last = def_opts.merge(args[-1]), -2
	    else options, last = def_opts, -1
	    end
	    xfetch *args[0..last], options
	end
    end

end

# "Private" module for XKeys::Set_* common code
module XKeys::Set_

    # Common code for XKeys::Set_Hash and XKeys::Set_Auto. This method
    # returns true if it is handling the set, or false if super should
    # handle the set.
    #
    #  _xset(key1, ..., keyN[, options_hash], value) { |key, options| block }
    #
    #  The block should return true to auto-vivify an array or false to
    #  auto-vivify a hash.
    #
    #  Options:
    #
    #  :[] => false
    #      Disable :[] auto-indexing
    def _xset (*args)
	if args[-2].is_a?(Hash) then options, last = args[-2], -3
	else options, last = {}, -2
	end
	if args.count + last == 0
	    if self.is_a?(Array) && args[0] == :[]
		self << args[-1]	# array[:[]] = value
	    else return false		# [key] = value ==> super
	    end
	else
	    # root[key1, ..., keyN[, option_hash]] = value
	    (node, key) = args[1..last].inject([self, args[0]]) do |node, key|
		if yield key, options
		    node[0][node[1]] ||= []
		    [node[0][node[1]], (key != :[]) ? key :
		      node[0][node[1]].size]
		else
		    node[0][node[1]] ||= {}
		    [node[0][node[1]], key]
		end
	    end
	    if yield key, options
		node[(key != :[])? key : node.size] = args[-1]
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
    # assignment syntax. :[] keys create nested arrays as needed. Other
    # keys, including integer keys, create nested hashes as needed.
    #
    #   root[key1, ..., keyN[, options_hash]] = value
    def []= (*args)
	super args[0], args[-1] unless _xset(*args) do |key, opts|
	  key == :[] and opts[:[]] != false
	end
	args[-1]
    end

end

# Extended set ([]=) with automatic selection of hash keys or array indexes
module XKeys::Set_Auto
    include XKeys::Set_

    # Auto-vivify nested hash and/or array trees using extended hash
    # key/array index assignment syntax. :[] keys and integer keys
    # create nested arrays as needed. Other keys create nested hashes
    # as needed.
    #
    #   root[key1, ..., keyN[, options_hash]] = value
    def []= (*args)
	super args[0], args[-1] unless _xset(*args) do |key, opts|
	    (key == :[] and opts[:[]] != false) or key.is_a?(Integer)
	end
	args[-1]
    end

end

# Combined interfaces

# XKeys::Hash combines XKeys::Get and XKeys::Set_Hash
module XKeys::Hash; include XKeys::Get; include XKeys::Set_Hash; end

# XKeys::Auto combines XKeys::Get and XKeys::Set_Auto
module XKeys::Auto; include XKeys::Get; include XKeys::Set_Auto; end

# END
