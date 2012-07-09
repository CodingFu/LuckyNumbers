#require "objspace"

MAX_DIGITS = 18
# Generating primes
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

Fixnum.class_eval do
  # returns length of number's digits
  def length
    number = self
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
    while number != 0
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
end

# Lucky table stores data in format table[squared_digits_sum][digits_sum] = numbers count
class LuckyTable
  
  def initialize(data={})
    @data = data
  end
  
  class << self
    # Returns table for 0..number
    def table_for(number)
      number += 1
      table = self.new
      max_power = number.length - 1
      left_part = 0
      number.each_digit_with_index do |digit, i|
        power = max_power - i
        t = table_for_power(power).shift_interval(digit)
        t = t.shift(left_part) unless left_part == 0
        table += t
        table
        left_part = left_part * 10 + digit
      end
      
      table
    end
    
    # Returns table including info on digit sums in interval 0...10**power
    def table_for_power(power)

      @@tables ||= [LuckyTable.new({ 0 => { 0 => 1 } })]
      unless @@tables[power]
        @@tables[power - 1] ||= table_for_power(power - 1)
        @@tables[power] = @@tables[power - 1].shift_interval(10)
      end
      
      @@tables[power]
    end
  end
  
  # 
  def shift(number)
    table = self.class.new
    sum = number.to_digits_array.inject(:+)
    squared_sum = number.to_digits_array.inject(0) {|s, v| s += v.to_i**2 }
    self.loop { |s2, s ,c| table[s2 + squared_sum][s + sum] += c }
    
    table
  end
  
  def shift_interval(digit, till=true)
    table = self.class.new
    interval = 0...digit
    loop do |squared_sum, digit_sum, count|
      for digit in interval
        square = digit ** 2
        new_squared_sum = square + squared_sum
        new_sum = digit + digit_sum
        table[new_squared_sum][new_sum] += count
      end
    end
    table
  end
  
  def loop()
    @data.each_pair do |squared_sum, digit_sums|
      digit_sums.each_pair do |digit_sum, count|
        yield(squared_sum, digit_sum, count)
      end
    end
  end
  
  def clone()
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
  
end

f = File.read("./tests.txt")


# n = gets.to_i
# n.times do
#   a, b = gets.split(' ').map(&:to_i)
f.lines.each do |line|
  a, b = line.split(' ').map(&:to_i)
  t = LuckyTable.table_for(b) - t = LuckyTable.table_for(a-1)

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
  
  puts count
end

