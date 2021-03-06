require 'spec_helper'

describe CR::Sanctorale do
  before :each do
    @s = described_class.new
  end

  describe '#get' do
    describe 'for empty day' do
      it 'returns an Array' do
        expect(@s.get(1,3)).to be_an Array
      end
    end

    describe 'for unempty day' do
      before :each do
        @c = CR::Celebration.new('S. Antonii, abbatis', CR::Ranks::MEMORIAL_GENERAL)
        @s.add 1, 17, @c
      end

      it 'get by month, day' do
        expect(@s.get(1, 17)).to eq [@c]
      end

      it 'get by Date' do
        expect(@s.get(Date.new(2014, 1, 17))).to eq [@c]
      end

      it 'may have more CR::Celebrations for a day' do
        [
         'S. Fabiani, papae et martyris',
         'S. Sebastiani, martyris'
        ].each {|t| @s.add 1, 20, CR::Celebration.new(t) }
        expect(@s.get(1, 20).size).to eq 2
      end
    end
  end

  describe '#add' do
    it 'adds a CR::Celebration to one month only' do
      @s.add 1, 17, CR::Celebration.new('S. Antonii, abbatis', CR::Ranks::MEMORIAL_GENERAL)
      expect(@s.get(2, 17)).to be_empty
    end

    it 'does not allow month 0' do
      expect { @s.add 0, 1, CR::Celebration.new('S. Nullius') }.to raise_exception RangeError
    end

    it 'does not allow month higher than 12' do
      expect { @s.add 13, 1, CR::Celebration.new('S. Nullius') }.to raise_exception RangeError
    end

    it 'adds solemnity to a dedicated container' do
      expect { @s.add 1, 13, CR::Celebration.new('S. Nullius', CR::Ranks::SOLEMNITY_PROPER) }.to change { @s.solemnities.size }.by 1
    end

    it 'does not add non-solemnity to solemnities' do
      expect { @s.add 1, 13, CR::Celebration.new('S. Nullius') }.not_to change { @s.solemnities.size }
    end
  end

  describe '#replace' do
    it 'replaces the original celebration(s)' do
      nemo = CR::Celebration.new('S. Nullius')
      nonus = CR::Celebration.new('S. Noni', CR::Ranks::SOLEMNITY_PROPER)

      @s.add 1, 13, nemo
      @s.replace 1, 13, [nonus]

      expect(@s.get(1, 13)).to eq [nonus]
    end

    it 'adds solemnity to a dedicated container' do
      nonus = CR::Celebration.new('S. Noni', CR::Ranks::SOLEMNITY_PROPER)
      expect do
        @s.replace 1, 13, [nonus]
      end.to change { @s.solemnities.size }.by 1
    end

    it 'removes solemnity' do
      nemo = CR::Celebration.new('S. Nullius', CR::Ranks::SOLEMNITY_PROPER)
      nonus = CR::Celebration.new('S. Noni')

      @s.add 1, 13, nemo
      expect do
        @s.replace 1, 13, [nonus]
      end.to change { @s.solemnities.size }.by -1
    end
  end

  describe '#update' do
    before :each do
      @s2 = described_class.new
    end

    it 'adds entries from the argument to receiver' do
      @s2.add 1, 17, CR::Celebration.new('S. Antonii, abbatis', CR::Ranks::MEMORIAL_GENERAL)

      expect(@s).to be_empty
      @s.update @s2
      expect(@s.size).to eq 1
    end

    it 'overwrites eventual previous content of the day' do
      @s.add 1, 17, CR::Celebration.new('S. Antonii, abbatis', CR::Ranks::MEMORIAL_GENERAL)
      cele = CR::Celebration.new('S. Nulius, monachi')
      @s2.add 1, 17, cele

      @s.update @s2
      expect(@s.get(1, 17)).to eq [cele]
    end
  end

  describe '#size' do
    it 'knows when the Sanctorale is empty' do
      expect(@s.size).to eq 0
    end

    it 'knows when there is something' do
      @s.add 1, 17, CR::Celebration.new('S. Antonii, abbatis', CR::Ranks::MEMORIAL_GENERAL)
      expect(@s.size).to eq 1
    end
  end

  describe '#empty?' do
    it 'is empty at the beginning' do
      expect(@s).to be_empty
    end

    it 'is never more empty once a record is entered' do
      @s.add 1, 17, CR::Celebration.new('S. Antonii, abbatis', CR::Ranks::MEMORIAL_GENERAL)
      expect(@s).not_to be_empty
    end
  end

  describe '#each_day' do
    it 'yields each date and corresponding CR::Celebrations' do
      cele = CR::Celebration.new('S. Antonii, abbatis', CR::Ranks::MEMORIAL_GENERAL)
      @s.add 1, 17, cele

      expect {|block| @s.each_day(&block) }.to yield_with_args(CR::AbstractDate.new(1, 17), [cele])
    end
  end
end
