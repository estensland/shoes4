require 'shoes/spec_helper'

describe Shoes::Dimensions do

  let(:left) {10}
  let(:top) {20}
  let(:width) {100}
  let(:height) {150}
  let(:parent) {Shoes::Dimensions.new left, top, width*2, height*2}
  subject {Shoes::Dimensions.new left, top, width, height}

  describe 'initialization' do
    describe 'without arguments' do
      subject {Shoes::Dimensions.new}

      its(:left) {should eq 0}
      its(:top) {should eq 0}
      its(:width) {should eq nil}
      its(:height) {should eq nil}
      its(:absolutely_positioned?) {should be_false}
      its(:absolute_x_position?) {should be_false}
      its(:absolute_y_position?) {should be_false}
    end

    describe 'with 2 arguments' do
      subject {Shoes::Dimensions.new left, top}

      its(:left) {should eq left}
      its(:top) {should eq top}
      its(:width) {should eq nil}
      its(:height) {should eq nil}
      its(:absolutely_positioned?) {should be_true}
      its(:absolute_x_position?) {should be_true}
      its(:absolute_y_position?) {should be_true}
    end

    describe 'with 4 arguments' do
      subject {Shoes::Dimensions.new left, top, width, height}

      its(:left) {should eq left}
      its(:top) {should eq top}
      its(:width) {should eq width}
      its(:height) {should eq height}
    end

    describe 'with relative width and height of parent' do
      subject {Shoes::Dimensions.new left, top, 0.5, 0.5, parent}

      its(:left) {should eq left}
      its(:top) {should eq top}
      its(:width) {should eq width}
      its(:height) {should eq height}
    end

    describe 'with relative width and height but no parent' do
      subject {Shoes::Dimensions.new left, top, 0.5, 0.5}

      its(:left) {should eq left}
      its(:top) {should eq top}
      its(:width) {should eq 0.5}
      its(:height) {should eq 0.5}
    end

    describe 'with a hash' do
      subject { Shoes::Dimensions.new left:   left,
                                      top:    top,
                                      width:  width,
                                      height: height }

      its(:left) {should eq left}
      its(:top) {should eq top}
      its(:width) {should eq width}
      its(:height) {should eq height}
      its(:absolutely_positioned?) {should be_true}
      its(:absolute_x_position?) {should be_true}
      its(:absolute_y_position?) {should be_true}

      context 'missing width' do
        subject { Shoes::Dimensions.new left:   left,
                                        top:    top,
                                        height: height }

        its(:width) {should eq nil}
      end
    end

    describe 'absolute_left and _top' do
      its(:absolute_left) {should eq nil}
      its(:absolute_top) {should eq nil}
    end

    describe 'absolute extra values' do
      it 'has an appropriate absolute_right' do
        subject.absolute_left = 10
        subject.absolute_right.should eq width + 10
      end

      it 'has an appropriate absolute_bottom' do
        subject.absolute_top = 15
        subject.absolute_bottom.should eq height + 15
      end
    end
  end

  describe 'setters' do
    it 'also has a setter for left' do
      subject.left = 66
      subject.left.should eq 66
    end
  end

  describe 'additional dimension methods' do
    its(:right) {should eq left + width}
    its(:bottom) {should eq top + height}

    describe 'without height and width' do
      let(:width) {nil}
      let(:height) {nil}
      its(:right) {should eq left}
      its(:bottom) {should eq top}
    end
  end

  describe 'in_bounds?' do
    it {should be_in_bounds 30, 40}
    it {should be_in_bounds left, top}
    it {should be_in_bounds left + width, top + height}
    it {should_not be_in_bounds 0, 0}
    it {should_not be_in_bounds 0, 40}
    it {should_not be_in_bounds 40, 0}
    it {should_not be_in_bounds 200, 50}
    it {should_not be_in_bounds 80, 400}
    it {should_not be_in_bounds 1000, 1000}
  end

  describe 'absolute positioning' do
    subject {Shoes::Dimensions.new}
    its(:absolutely_positioned?) {should be_false}

    describe 'changing left' do
      before :each do
        subject.left = left
      end

      its(:absolute_x_position?) {should be_true}
      its(:absolute_y_position?) {should be_false}
      its(:absolutely_positioned?) {should be_true}
    end

    describe 'changing top' do
      before :each do
        subject.top = top
      end

      its(:absolute_x_position?) {should be_false}
      its(:absolute_y_position?) {should be_true}
      its(:absolutely_positioned?) {should be_true}
    end
  end

  describe Shoes::AbsoluteDimensions do
    subject {Shoes::AbsoluteDimensions.new left, top, width, height}
    it 'has the same absolute_left as left' do
      subject.absolute_left.should eq left
    end

    it 'has the same absolute_top as top' do
      subject.absolute_top.should eq top
    end
  end
end

describe Shoes::DimensionsDelegations do

  describe 'with a DSL class and a dimensions method' do
    let(:dimensions) {double('dimensions')}

    class DummyClass
      include Shoes::DimensionsDelegations
      def dimensions
      end
    end

    subject do
      dummy = DummyClass.new
      dummy.stub dimensions: dimensions
      dummy
    end

    it 'forwards left calls to dimensions' do
      dimensions.should_receive :left
      subject.left
    end

    it 'forwards bottom calls to dimensions' do
      dimensions.should_receive :bottom
      subject.bottom
    end

    it 'forwards setter calls like left= do dimensions' do
      dimensions.should_receive :left=
      subject.left = 66
    end

    it 'forwards absolutely_positioned? calls to the dimensions' do
      dimensions.should_receive :absolutely_positioned?
      subject.absolutely_positioned?
    end
  end

  describe 'with any backend class that has a defined dsl method' do
    let(:dsl){double 'dsl'}

    class AnotherDummyClass
      include Shoes::BackendDimensionsDelegations
      def dsl
      end
    end

    subject do
      dummy = AnotherDummyClass.new
      dummy.stub dsl: dsl
      dummy
    end

    it 'forwards calls to dsl' do
      dsl.should_receive :left
      subject.left
    end
  end

end