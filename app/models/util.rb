class Class
	def accessors_through(hash, things)
		things.each do |thing|
			define_method thing.to_s do
				#puts "accessing " + thing.to_s
				got = self.send(hash)
				#puts got
				got[thing]
			end
			define_method (thing.to_s+"=") do |v| 
				self.send(hash)[thing] = v 
			end
		end
	end
	
end

class Random
	def self.value; rand(1.0) end
	def self.range(a,b) a+rand(b-a) end
end

class Numeric
	def clamp(min, max) if self<=min;min elsif self>=max;max else self end end
	def clamp01() if self<=0;0 elsif self>=1;1 else self end end
	def ratio(r) (1.0 - (1.0 - self.clamp01) * (1.0 - r.clamp01)) end
end

class String
	def prefix?(v) start_with?(v) end
	def suffix?(v) end_with?(v) end
	def contains?(v) include?(v) end
	
	def prefix_with(v) (v+self) end
	def suffix_with(v) (self+v) end
end

class Symbol
	def prefix?(v) to_s.prefix?(v) end
	def suffix?(v) to_s.suffix?(v) end
	def contains?(v) to_s.contains?(v) end
	
	def prefix_with(v) to_s.prefix_with(v).to_sym end
	def suffix_with(v) to_s.suffix_with(v).to_sym end
end

class Array
	def choose; self[Random.new.rand(length)] end
	
end


class Hash
	
	#Mask this hash with an array of symbols, or another hash
	#Returns a hash with self.keys intersect m, and their values
	def mask(m)
		c = {}
		
		case m
			when Hash; self.each { |k, v| if m.has_key? k; c[k] = v end }
			when Array; self.each { |k, v| if m.include? k; c[k] = v end }
			else;
		end
		
		
		c
	end

	def extract(key, default) if has_key? key; self[key] else; default end end
	def xt(key, default) if has_key? key; self[key] else; default end end

	def get_matching_keys(rule)
		if rule.nil?; rule = {} end
		result = []
		pf = rule.extract :prefix, ""
		sf = rule.extract :suffix, ""
		cn = rule.extract :contains, ""
		
		self.each {|k, v| 
			if k.prefix?(pf) && k.suffix?(sf) && k.contains?(cn)
				result.push k
			end
		}
		result
	end
	
	def neg; c = {}; c.default = 0; self.each {|k, v| c[k] = -v}; c end
	def sum; s = 0; self.each {|k,v| s += v}; s; end
	
	def set!(b) b.each { |k,v| self[k] = v }end
	
	def add(b)
		c = {};	c.default = 0
		case b
			when Hash; self.each { |k, v| c[k] = v }; b.each {|k, v| c[k] += v }
			when Numeric; self.each { |k, v| c[k] = v + b }
		end
		c
	end
	
	def mul(b)
		c = {};	c.default = 0
		case b
			when Hash; self.each { |k, v| if b.has_key? k; c[k] = v * b[k] end }
			when Numeric; self.each { |k, v| c[k] = v * b }
		end
		c
	end

	def rat(b)
		c = {}; c.default = 0
		self.each { |k,v| c[k] = c[k].ratio(v) }
		b.each { |k,v| c[k] = c[k].ratio(v) }
		c
	end

	def matmul(b)
		c = {};	c.default = 0
		b.each do |k, v|
			r = 0;
			case v
				when Hash; v.each { |kk, vv| r += self[kk] * vv }
				when Numeric; r = self[k] * v;
			end
			c[k] = r
		end
		c
	end
	
	def combine(b, method)
		c = {}; c.default = 0
		self.each { |k, v| c[k] = v }
		b.each { |k, v| c[k] = method.call(c[k], v) }
		c
	end
	
	def combine!(b, method)
		b.each { |k, v| if has_key? k; self[k] = method.call(self[k], v) end }
	end

end