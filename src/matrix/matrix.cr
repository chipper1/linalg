require "complex"

module Linalg
  # TODO - Complex64?
  SUPPORTED_TYPES = {Float32, Float64, Complex}

  @[Flags]
  enum MatrixFlags
    Symmetric
    Hermitian
    PositiveDefinite
    Hessenberg
    Band
    Diagonal
    Bidiagonal
    Tridiagonal
    Triangular
    Orthogonal

    Virtual # compute values instead of storing, so have to be cloned before to_unsafe
  end

  # class that provide all utility matrix functions
  # TODO - iteration on cols\rows (create row\column object to prevent allocations?)
  # TODO - sums on cols\rows, check numpy for more (require previous point?)
  # TODO - saving/loading to files (what formats? csv?)
  module Matrix(T)
    # used in constructors to limit T at compile-time
    protected def check_type
      {% unless T == Float32 || T == Float64 || T == Complex %}
          {% raise "Wrong matrix members type: #{T}. Types supported by Linalg are: #{SUPPORTED_TYPES}" %}
        {% end %}
    end

    # to_unsafe method raises at runtime and is overriden by matrix that actually have pointer
    def to_unsafe
      raise ArgumentError.new("Matrix can't be passed unsafe!")
    end

    # creates actual matrix with same content. Useful for virtual matrices
    def clone
      GeneralMatrix(T).new(rows, columns) do |i, j|
        unsafe_at(i, j)
      end
    end

    # matrix product to given m
    def *(m : self)
      if columns != m.rows
        raise ArgumentError.new("matrix size should match ([#{rows}x#{columns}] * [#{m.rows}x#{m.columns}]")
      end
      result = GeneralMatrix(T).new(rows, m.columns) do |i, j|
        (0...columns).sum { |k| self[i, k]*m[k, j] }
      end
    end

    # multiplies at scalar
    def *(k : Int | Float | Complex)
      result = GeneralMatrix(T).new(rows, columns) do |i, j|
        self[i, j]*k
      end
    end

    # returns element-wise sum
    def +(m : self)
      if columns != m.columns || rows != m.rows
        raise ArgumentError.new("matrix size should match ([#{rows}x#{columns}] + [#{m.rows}x#{m.columns}]")
      end
      result = GeneralMatrix(T).new(rows, columns) do |i, j|
        self[i, j] + m[i, j]
      end
    end

    # returns element-wise subtract
    def -(m : self)
      if columns != m.columns || rows != m.rows
        raise ArgumentError.new("matrix size should match ([#{rows}x#{columns}] - [#{m.rows}x#{m.columns}]")
      end
      result = GeneralMatrix(T).new(rows, columns) do |i, j|
        self[i, j] - m[i, j]
      end
    end

    # returns matrix norm
    # TODO - proper norms
    def abs
      (0...rows).map { |r| (0...columns).sum { |c| self[r, c].abs } }.max
    end

    # returns transposed matrix
    def transpose
      GeneralMatrix(T).new(columns, rows) do |i, j|
        self[j, i]
      end
    end

    # retunrs
    def kron(b : self)
      Matrix(T).kron(self, b)
    end

    def tril(k = 0)
      GeneralMatrix(T).new(rows, columns) do |i, j|
        i >= j - k ? self[i, j] : 0
      end
    end

    def triu(k = 0)
      GeneralMatrix(T).new(rows, columns) do |i, j|
        i <= j - k ? self[i, j] : 0
      end
    end

    def to_s(io)
      io << "\n"
      rows.times do |i|
        io << "["
        columns.times do |j|
          io << ", " unless j == 0
          io << self[i, j]
        end
        io << "]\n"
      end
      io << "\n"
    end

    def reshape(arows, acolumns)
      clone.reshape!(arows, acolumns)
    end

    def square?
      rows == columns
    end

    def repmat(arows, acolumns)
      GeneralMatrix(T).new(rows*arows, columns*acolumns) do |i, j|
        self[i % rows, j % columns]
      end
    end

    def [](rows : Range(Int32, Int32), columns : Range(Int32, Int32))
      nrows = rows.end + (rows.excludes_end? ? 0 : 1) - rows.begin
      ncols = columns.end + (columns.excludes_end? ? 0 : 1) - columns.begin
      SubMatrix(T).new(self, {rows.begin, columns.begin}, {nrows, ncols})
    end

    def row(i)
      SubMatrix(T).new(self, {i, 0}, {1, columns})
    end

    def column(i)
      SubMatrix(T).new(self, {0, i}, {rows, 1})
    end

    def [](i, j)
      if j >= 0 && j < columns && i >= 0 && i < rows
        unsafe_at(i, j)
      else
        raise IndexError.new("access to [#{i}, #{j}] in matrix with size #{rows}x#{columns}")
      end
    end

    def []=(i, j, value)
      # i isn't checked as underlying array will check it anyway
      if j >= 0 && j < columns && i >= 0 && i < rows
        unsafe_set(i, j, value)
      else
        raise IndexError.new("access to [#{i}, #{j}] in matrix with size #{rows}x#{columns}")
      end
    end

    def self.rand(rows, columns, rng = Random::DEFAULT)
      GeneralMatrix(T).new(rows, columns) { |i, j| rng.rand }
    end

    def self.zeros(rows, columns)
      GeneralMatrix(T).new(rows, columns)
    end

    def self.ones(rows, columns)
      GeneralMatrix(T).new(rows, columns) { |i, j| 1 }
    end

    def self.repmat(a : self, rows, columns)
      a.repmat(rows, columns)
    end

    def self.diag(arows, acolumns, value : Int | Float | Complex)
      diag(arows, acolumns) { value }
    end

    def self.diag(arows, acolumns, values)
      GeneralMatrix(T).new(arows, acolumns) do |i, j|
        i == j ? values[i] : 0
      end
    end

    def self.diag(values)
      diag(values.size, values.size, values)
    end

    def self.diag(arows, acolumns, &block)
      GeneralMatrix(T).new(arows, acolumns) do |i, j|
        i == j ? yield(i) : 0
      end
    end

    def self.kron(a, b)
      GeneralMatrix(T).new(a.rows*b.rows, a.columns*b.columns) do |i, j|
        a[i / b.rows, j / b.columns] * b[i % b.rows, j % b.columns]
      end
    end

    def self.tri(rows, columns, k = 0)
      GeneralMatrix(T).new(rows, columns) do |i, j|
        i >= j - k ? 1 : 0
      end
    end

    def self.identity(n)
      GeneralMatrix(T).new(n, n) { |i, j| i == j ? 1 : 0 }
    end
  end

  alias Mat = Matrix(Float64)
  alias Mat32 = Matrix(Float32)
  alias MatComplex = Matrix(Complex)
end
