require "./spec_helper"

include Linalg
describe Linalg::Matrix do
  it "can be created with given size" do
    m = Matrix(Float64).new(10, 15)
    m.raw.size.should eq 10*15
    m.raw[0].should eq 0
  end

  it "can be created from array with given dimension" do
    m = Matrix(Float64).new(3, 4, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
    m.rows.should eq 3
    m[1, 0].should eq 5
  end

  it "can be created from array of arrays" do
    m = Matrix(Float64).new({ {1, 2, 3}, {4, 5, 6}, {7, 8, 9}, {10, 11, 12} })
    m.rows.should eq 4
    m.columns.should eq 3
    m[1, 0].should eq 4
    expect_raises(IndexError) { Matrix(Float64).new({ {1, 2, 3}, {4, 5} }) }
  end

  it "can be created from a dimensions and a block" do
    m = Matrix(Float32).new(3, 3) { |i, j| i*3 + j }
    m[1, 1].should eq 4
  end

  it "can't create matrix of unsupported type" do
    # commented as it causes a compile error, as it should
    # m = Matrix(Int32).new(3, 3)
  end

  it "access to members works and is zero-based" do
    m = Matrix(Float64).new(5, 4)
    m[4, 3] = 1.0
    m[4, 3].should eq 1.0
    expect_raises(IndexError) { m[5, 4] = 1.0 }
    expect_raises(IndexError) { m[0, 6] = 1.0 }
  end

  it "can multiply matrices" do
    m1 = Matrix(Float64).new(3, 4) { |i, j| i + j }
    m2 = Matrix(Float64).new(4, 2) { |i, j| i - j }
    m = m1*m2
    m.should eq Matrix(Float64).new(3, 2, [14.0, 8.0, 20.0, 10.0, 26.0, 12.0])
    expect_raises(ArgumentError) { Matrix(Float64).new(3, 4) * Matrix(Float64).new(3, 4) }
  end

  it "can do sum and scalar multiply" do
    m1 = Matrix(Float64).new(3, 4) { |i, j| i }
    m2 = Matrix(Float64).new(3, 4) { |i, j| j }
    m = m1 + m2*2
    m.should eq Matrix(Float64).new(3, 4) { |i, j| i + 2*j }
    expect_raises(ArgumentError) { Matrix(Float64).new(3, 4) + Matrix(Float64).new(4, 4) }
  end

  it "can checks if it is square" do
    Matrix(Float64).new(3, 4).square?.should be_false
    Matrix(Complex).new(30, 30).square?.should be_true
  end

  it "can be initialized with zeros and ones" do
    m = Matrix(Float64).identity(3).should eq Matrix(Float64).new([[1, 0, 0], [0, 1, 0], [0, 0, 1]])
    m = Matrix(Float64).zeros(2, 2).should eq Matrix(Float64).new([[0, 0], [0, 0]])
    m = Matrix(Float64).ones(1, 3).should eq Matrix(Float64).new([[1, 1, 1]])
  end

  it "can be initialized with random vales" do
    rng1 = Random.new(1)
    m1 = Matrix(Complex).rand(5, 5, rng1)
    rng2 = Random.new(1)
    m2 = Matrix(Complex).rand(5, 5, rng2)
    m3 = Matrix(Complex).rand(5, 5)
    m1.should eq m2
    m1.should_not eq m3
  end

  it "can be constructed using repmat" do
    a = Matrix(Float64).new([[1, 2]])
    b = a.repmat(5, 3)
    b.should eq Matrix(Float64).new([
      [1, 2, 1, 2, 1, 2],
      [1, 2, 1, 2, 1, 2],
      [1, 2, 1, 2, 1, 2],
      [1, 2, 1, 2, 1, 2],
      [1, 2, 1, 2, 1, 2],
    ])
    c = Matrix(Float64).repmat(a, 2, 1)
    c.should eq Matrix(Float64).new([
      [1, 2],
      [1, 2],
    ])
  end

  it "can be constructed with diagonal elements" do
    Matrix(Float32).diag(2, 2, 5).should eq Matrix(Float32).new([[5, 0], [0, 5]])
    Matrix(Float32).diag(3, 2) { |i| -i - 1 }.should eq Matrix(Float32).new([[-1, 0], [0, -2], [0, 0]])
    Matrix(Float32).diag(2, 3, [14, 15]).should eq Matrix(Float32).new([[14, 0, 0], [0, 15, 0]])
  end

  it "can be trasposed" do
    m = Matrix(Float64).new([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
    mt = m.transpose
    mt.should eq Matrix(Float64).new([[1, 4, 7], [2, 5, 8], [3, 6, 9]])

    m = Matrix(Float64).new([[1, 2, 3, 4], [5, 6, 7, 8]])
    mt = m.transpose
    mt.should eq Matrix(Float64).new([[1, 5], [2, 6], [3, 7], [4, 8]])
  end
  it "can be trasposed inplace (square case)" do
    m = Matrix(Float64).new([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
    m.transpose!
    m.should eq Matrix(Float64).new([[1, 4, 7], [2, 5, 8], [3, 6, 9]])
  end
  pending "can be trasposed inplace (rectangular case)" do
    m = Matrix(Float64).new([[1, 2, 3, 4], [5, 6, 7, 8]])
    m.transpose!
    m.should eq Matrix(Float64).new([[1, 5], [2, 6], [3, 7], [4, 8]])
  end

  it "has kron operation" do
    a = Matrix(Float64).new([[1, 2], [3, 4]])
    b = Matrix(Float64).new([[1, -1, 1]])
    Matrix(Float64).kron(a, b).should eq Matrix(Float64).new([
      [1, -1, 1, 2, -2, 2],
      [3, -3, 3, 4, -4, 4],
    ])
  end
end
