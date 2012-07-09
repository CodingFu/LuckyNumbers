MAX_DIGITS = 17

###################################################
# Adding new methods to Fixnum and Bignum classes #
###################################################
[Fixnum, Bignum].each do |klass|
  klass.class_eval do
    # returns count of digits in number
    def length
      number = self
      return 1 if number == 0
      len = 0
      while number != 0
        number /= 10
        len += 1
      end
    
      len
    end
    
    def each_digit
      number = self
      k = 10**number.length
      while k != 1
        k /= 10
        yield(number / k)
        number %= k
      end
    end
  
    def each_digit_with_index
      index = 0
      self.each_digit do |digit|
        yield(digit, index)
        index += 1
      end
    end
  
    def to_digits_array
      array = []
      self.each_digit { |d| array << d }
    
      array
    end
    
    def sum_of_digits
      self.to_digits_array.inject(:+)
    end
    
    def sum_of_squared_digits
      self.to_digits_array.inject(0) {|s, v| s += v.to_i**2 }
    end
    
    def power_of_ten?
      number = self
      len = number.length
      closest = 10**(len-1)
      
      number/closest == 1 && number%closest == 0 
    end
    
  end
end

################################################
# LuckyTable class                             #
#                                              #
# Stores count of occurances for each pair of  #
# sum of digits and sum of squared digits      #
# for all the integers in given interval.      #
################################################
class LuckyTable
  def initialize(data={})
    @data = data
  end
  
  # shifts table by specified number
  # { [1,1] => 2, [4, 2]=> 3 }.shift(1) --> { [2,2] => 2, [5, 3]=> 3 } 
  def shift(number)
    return self.clone if number == 0
    table = self.class.new
    sum = number.sum_of_digits
    squared_sum = number.sum_of_squared_digits
    self.loop do |s2, s ,c|
      table[s2 + squared_sum] ||= {}
      table[s2 + squared_sum][s + sum] ||= 0
      table[s2 + squared_sum][s + sum] += c
    end
    
    table
  end
  
  def loop
    @data.each_pair do |squared_sum, digit_sums|
      digit_sums.each_pair do |digit_sum, count|
        yield(squared_sum, digit_sum, count)
      end
    end
  end
  
  def clone
    table = self.class.new
    self.loop { |s2, s, c| table[s2][s] = c }
    
    table
  end
  
  def +(another_table)
    table = clone
    another_table.loop { |s2, s, c| table[s2][s] += c }
    
    table
  end
  
  def -(another_table)
    table = clone
    another_table.loop { |s2, s, c| table[s2][s] -= c }
    
    table
  end
  
  def [](squared_sum)
    @data[squared_sum] ||= Hash.new(0)
    @data[squared_sum]
  end
  
  def []=(squared_sum, val)
    @data[squared_sum] ||= Hash.new(0)
    @data[squared_sum] = val
  end
  
  class << self
    # returns table for [0;number)
    def for_number(number)
      return self.new if number == 0
      @@storage ||= { 1 => self.new({ 0 => {0 => 1} }) }
      return @@storage[number] if @@storage[number]
      
      number.power_of_ten? ? for_power_of_ten(number) : for_regular_number(number)
    end
    
    private
    
    # returns table for [0;number) where number is power of ten
    # also caches tables for [0;k*10**n) intervals
    # where k is in [0;0] and n is log10(number) - 1
    def for_power_of_ten(number)
      prev_power = number/10
      @@storage[prev_power] ||= for_number(prev_power)
      for digit in 1..9
        @@storage[(digit+1) * prev_power] = @@storage[digit * prev_power] + @@storage[prev_power].shift(digit*prev_power)
      end
      return @@storage[number]
    end
    
    # returns table for [0;number) where number is NOT power of ten
    def for_regular_number(number)
      table = self.new
      for_number(10**number.length) # doing this because to count.. TODO: move
      max_power = number.length - 1
      left_part = 0
      number.each_digit_with_index do |digit, i|
        power = max_power - i
        t = for_number(digit * 10**power).shift(left_part)
        table += t
        left_part = left_part * 10 + digit
      end
      
      table
    end
  end
end


#####################
# Generating primes #
#####################
primes = [2]
for i in 3..(9*9*MAX_DIGITS)
  is_prime = true
  for prime in primes
    if i % prime == 0
      is_prime = false
      break
    end
  end
  primes.push i if is_prime
end

################
# Handling I/O #
################
n = gets.to_i
answers = []
n.times do
  a, b = gets.split(' ').map(&:to_i)
  t = LuckyTable.for_number(b+1) - t = LuckyTable.for_number(a)

  count = 0
  for i in primes
    break if i > 9 * 9 * 18
    if t[i]
      for j in primes
        break if j > 9 * 18
        c = t[i][j]
        count += c if c
      end
    end
  end
  
  answers << count
end

puts answers.join("\n")
