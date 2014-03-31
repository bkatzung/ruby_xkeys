# XKeys - Extended keys to facilitate fetching and storing in nested
#	hash- and array-like structures with Perl-ish auto-vivification.
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
# As of version 2, other types with array- or hash-like behavior are
# supported as well.
#
# Version 2.0.0 2014-03-21
#
# @author Brian Katzung <briank@kappacs.com>, Kappa Computer Solutions, LLC
# @copyright 2013-2014 Brian Katzung and Kappa Computer Solutions, LLC
# @license MIT License

module XKeys; end

# Extended fetch and get ([])
module XKeys::Get

    # Perform an extended fetch using successive keys to traverse a tree
    # of nested hash- and/or array-like objects.
    #
    #   xfetch(key1, ..., keyN [, option_hash])
    #
    # Options:
    #
    #   :else => default value
    #       The default value to return if any of the keys do not exist
    #       (when an underlying #fetch generates a KeyError or IndexError).
    #       The :raise option takes precedence.
    #
    #   :raise => true
    #       Re-raise the original KeyError or IndexError if any of the keys
    #       do not exist. This is the default behavior for xfetch in the
    #       absence of an :else option.
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
		if options[:raise] && options[:raise] != true
		    raise *options[:raise]
		elsif options[:raise] || !options.has_key?(:else)
		    raise
		else return options[:else]
		end
	    end
	end
    end

    # Perform an extended get using successive keys to traverse a tree of
    # nested hashes and/or arrays.
    #
    # [key] or [range] returns the normal hash or array element (or
    # range-based array slice).
    #
    # [int1, int2] for arrays (or other objects responding to the #slice
    # method) returns the object's normal two-parameter (e.g. start + length
    # slice) index value.
    #
    # [key1, ..., keyN[, option_hash]] traverses a tree of nested
    # hash- and/or array-like objects using xfetch.
    #
    # Option :else => nil is used if no :else option is supplied.
    # See xfetch for option details.
    def [] (*args)
	if args.count == 1 || (respond_to?(:slice) && args.count == 2 &&
	  args[0].is_a?(Integer) && args[1].is_a?(Integer))
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
    # returns true if it is handling the set, or false if the caller
    # should super to handle the set.
    #
    #  _xkeys_set(key1, ..., keyN[, option_hash], value) { |key, options| block }
    #
    # If the root of the tree responds to the #xkeys_new method, it will
    # be called as follows whenever a new node needs to be created:
    #
    #  xkeys_new(key2, info_hash, option_hash)
    #
    # where info_hash contains
    #
    #  :node => The current node
    #  :key1 => The key in the current node, or :[]
    #  :block => The block passed to _xkeys_set
    #
    # The returned new node will be assigned to node[key1] (or pushed onto
    # the end of the array) and should be appropriate to accept key2.
    #
    # Otherwise, the block should return true for array-like keys or false
    # for hash-like keys. An array or hash node will be added accordingly.
    #
    # If a key is :[], the current node responds to the #push method, and
    # push mode has not been disabled (see below), a new node will be
    # pushed onto the end of the current node.
    #
    # Options:
    #
    #  :[] => false
    #      Disable :[] push mode
    def _xkeys_set (*args, &block)
	if args[-2].is_a?(Hash) then options, last = args[-2], -3
	else options, last = {}, -2
	end

	push_mode = options[:[]] != false

	if args.count + last == 0
	    if args[0] == :[] && push_mode && respond_to?(:push)
		push args[-1]		# array[:[]] = value
		true			# done--don't caller-super
	    else false			# use caller-super to do it
	    end
	else
	    # root[key1, ..., keyN[, option_hash]] = value
	    (node, key) = args[1..last].inject([self, args[0]]) do |nk1, k2|
		if nk1[1] == :[] && push_mode && nk1[0].respond_to?(:push)
		    # Push a new node onto an array-like node
		    node = _xkeys_new(k2, { :node => nk1[0],
		      :key1 => nk1[1], :block => block }, options)
		    nk1[0].push node
		    [node, k2]
		elsif nk1[0][nk1[1]].nil?
		    # Auto-vivify the specified key/index
		    node = _xkeys_new(k2, { :node => nk1[0],
		      :key1 => nk1[1], :block => block }, options)
		    nk1[0][nk1[1]] = node
		    [node, k2]
		else
		    # Traverse an existing node
		    [nk1[0][nk1[1]], k2]
		end
	    end

	    # Assign (or push) according to the final key.
	    if key == :[] && push_mode && node.respond_to?(:push)
		node.push args[-1]
	    else
		node[key] = args[-1]
	    end
	    true	# done--don't caller-super
	end
    end

    # Return a new node for node[key1] suitable to hold key2.
    # Either key1 or key2 (or both) may be :[].
    def _xkeys_new (key2, info, options)
	if respond_to? :xkeys_new
	    # Note: #xkeys_new is responsible for cloning extensions
	    # as desired or needed.
	    xkeys_new key2, info, options
	else
	    node = info[:block].call(key2, options) ? [] : {}

	    # Clone XKeys extensions from the root node
	    node.extend XKeys::Get if is_a? XKeys::Get
	    node.extend XKeys::Set_Auto if is_a? XKeys::Set_Auto
	    node.extend XKeys::Set_Hash if is_a? XKeys::Set_Hash

	    node
	end
    end

end

# Extended set ([]=) with hash keys
module XKeys::Set_Hash
    include XKeys::Set_

    # Auto-vivify nested hash trees using extended hash key/array index
    # assignment syntax. :[] keys create nested arrays as needed. Other
    # keys, including integer keys, create nested hashes as needed.
    #
    # See XKeys::Set_ for additional information.
    #
    #   root[key1, ..., keyN[, option_hash]] = value
    def []= (*args)
	super args[0], args[-1] unless _xkeys_set(*args) do |key, options|
	  key == :[] && options[:[]] != false
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
    # See XKeys::Set_ for additional information.
    #
    #   root[key1, ..., keyN[, option_hash]] = value
    def []= (*args)
	super args[0], args[-1] unless _xkeys_set(*args) do |key, options|
	    (key == :[] && options[:[]] != false) || key.is_a?(Integer)
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
