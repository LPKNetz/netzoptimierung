#ifndef MATRIX_H
#define MATRIX_H

class Matrix
{
public:
    Matrix(int n, int m);
    Matrix(const Matrix& src);


    int index( int n, int m ) const { return m + m_m * n; }
    double at(int n, int m);
    int m_n, m_m;
    double *A;

    Matrix operator+(const Matrix& rhs);
    Matrix operator-(const Matrix& rhs);
    Matrix operator*(Matrix rhs);

    Matrix invert();

};

#endif // MATRIX_H
