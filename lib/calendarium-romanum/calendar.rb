require 'date'
require 'forwardable'

module CalendariumRomanum

  # calendar computations according to the Roman Catholic liturgical
  # calendar as instituted by
  # MP Mysterii Paschalis of Paul VI. (AAS 61 (1969), pp. 222-226)
  class Calendar

    extend Forwardable
    def_delegators :@temporale, :range_check
    def_delegators :@sanctorale, :add, :validate_date

    # year: Integer
    # returns a calendar for the liturgical year beginning with
    # Advent of the specified civil year.
    def initialize(year)
      @year = year
      @temporale = Temporale.new(year)
      @sanctorale = Sanctorale.new
    end

    attr_reader :year
    attr_accessor :sanctorale

    # returns a Calendar for the subsequent year
    def succ
      c = Calendar.new @year + 1
      c.sanctorale = @sanctorale
      return c
    end

    # returns a Calendar for the previous year
    def pred
      c = Calendar.new @year - 1
      c.sanctorale = @sanctorale
      return c
    end

    def ==(obj)
      unless obj.is_a? Calendar
        return false
      end

      return year == obj.year
    end

    # returns filled Day for the specified day
    def day(*args)
      if args.size == 2
        date = Date.new(@year, *args)
        unless @temporale.dt_range.include? date
          date = Date.new(@year + 1, *args)
        end
      else
        date = self.class.mk_date *args
        range_check date
      end

      s = @temporale.season(date)
      return Day.new(
                     date: date,
                     season: s,
                     season_week: @temporale.season_week(s, date),
                     celebrations: celebrations_for(date)
                    )
    end

    # Sunday lectionary cycle
    def lectionary
      LECTIONARY_CYCLES[@year % 3]
    end

    # Ferial lectionary cycle
    def ferial_lectionary
      @year % 2 + 1
    end

    def celebrations_for(date)
      t = @temporale.get date
      st = @sanctorale.get date

      unless st.empty?
        if st.first.rank > t.rank
          if st.first.rank == Ranks::MEMORIAL_OPTIONAL
            st.unshift t
            return st
          else
            return st
          end
        end
      end

      return [t]
    end

    class << self
      # day(Date d)
      # day(Integer year, Integer month, Integer day)
      def day(*args)
        date = mk_date(*args)

        return for_day(date).day(date)
      end

      def mk_date(*args)
        ex = TypeError.new('Date, DateTime or three Integers expected')

        if args.size == 3 then
          args.each do |a|
            unless a.is_a? Integer
              raise ex
            end
          end
          return Date.new *args

        elsif args.size == 1 then
          a = args.first
          unless a.is_a? Date or a.is_a? DateTime
            raise ex
          end
          return a

        else
          raise ex
        end
      end

      # creates a Calendar for the liturgical year including given
      # date
      def for_day(date)
        return new(Temporale.liturgical_year(date))
      end
    end # class << self
  end # class Calendar
end
