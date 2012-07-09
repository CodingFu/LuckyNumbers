MAX_DIGITS = 17
PRIMES =[ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53,
          59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113,
          127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181,
          191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251,
          257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313, 317,
          331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 397,
          401, 409, 419, 421, 431, 433, 439, 443, 449, 457, 461, 463,
          467, 479, 487, 491, 499, 503, 509, 521, 523, 541, 547, 557,
          563, 569, 571, 577, 587, 593, 599, 601, 607, 613, 617, 619,
          631, 641, 643, 647, 653, 659, 661, 673, 677, 683, 691, 701,
          709, 719, 727, 733, 739, 743, 751, 757, 761, 769, 773, 787,
          797, 809, 811, 821, 823, 827, 829, 839, 853, 857, 859, 863,
          877, 881, 883, 887, 907, 911, 919, 929, 937, 941, 947, 953,
          967, 971, 977, 983, 991, 997, 1009, 1013, 1019, 1021, 1031,
          1033, 1039, 1049, 1051, 1061, 1063, 1069, 1087, 1091, 1093,
          1097, 1103, 1109, 1117, 1123, 1129, 1151, 1153, 1163, 1171,
          1181, 1187, 1193, 1201, 1213, 1217, 1223, 1229, 1231, 1237,
          1249, 1259, 1277, 1279, 1283, 1289, 1291, 1297, 1301, 130103,
          1307, 1319, 1321, 1327, 1361, 1367, 1373 ] 

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
      each_digit do |digit|
        yield(digit, index)
        index += 1
      end
    end
  
    def to_digits_array
      array = []
      each_digit { |d| array << d }
    
      array
    end
    
    def sum_of_digits
      to_digits_array.inject(:+)
    end
    
    def sum_of_squared_digits
      to_digits_array.inject(0) {|s, v| s += v.to_i**2 }
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
    return clone if number == 0
    table = self.class.new
    sum = number.sum_of_digits
    squared_sum = number.sum_of_squared_digits
    loop do |squared_sum_before, sum_before, count_before|
      table[squared_sum_before + squared_sum] ||= {}
      table[squared_sum_before + squared_sum][sum_before + sum] ||= 0
      table[squared_sum_before + squared_sum][sum_before + sum] += count_before
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
    another_table.loop do |squared_sum, digit_sum, count|
      table[squared_sum][digit_sum] ||= 0
      table[squared_sum][digit_sum] += count
    end
    
    table
  end
  
  def -(another_table)
    table = clone
    another_table.loop do |squared_sum, digit_sum, count|
      table[squared_sum][digit_sum] ||= 0
      table[squared_sum][digit_sum] -= count
    end
    
    table
  end
  
  def [](squared_sum)
    @data[squared_sum] ||= {}
    @data[squared_sum]
  end
  
  def []=(squared_sum, val)
    @data[squared_sum] ||= {}
    @data[squared_sum] = val
  end
  
  class << self
    # returns table for [0;number)
    def for_number(number)
      return self.new if number == 0
      build_storage
      return @@storage[number] if @@storage[number]
      
      number.power_of_ten? ? for_power_of_ten(number) : for_regular_number(number)
    end
    
    private
    
    def build_storage
        @@storage ||= {1 => LuckyTable.new({ 0 => {0 => 1} })}
    end
    
    # returns table for [0;number) where number is power of ten
    # caches tables for [0; k*10^(n-1)) where n is log10(number)
    # for example, for_power_of_ten(100) 
    # will also cache tables for [0;10), [0;20), ... , [0;90)
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
      max_power = number.length - 1
      for_number(10**number.length) # caching [0; k*10**max_power)
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

################
# Handling I/O #
################
n = gets.to_i
n.times.do
  a, b = gets.split(' ').map(&:to_i)
  t = LuckyTable.for_number(b+1) - t = LuckyTable.for_number(a)
  
  max_digits_sum = 9 * b.length
  max_squared_sum = 9 * max_digits_sum
  count = 0
  PRIMES.each do |i|
    break if i > max_squared_sum
    if t[i]
      PRIMES.each do |j|
        break if j > max_digits_sum
        c = t[i][j]
        count += c if c
      end
    end
  end
  
  puts count
end
