#ifndef MATRIX_H
#define MATRIX_H

#include <QString>

class Matrix
{
public:
    Matrix();
    Matrix(int n, int m);
    Matrix(const Matrix& src);
    ~Matrix();

    double at(int n, int m);
    void fill(int n, int m, double a);

    Matrix operator+(const Matrix& rhs);
    Matrix operator-(const Matrix& rhs);
    Matrix operator*(Matrix rhs);

    Matrix invert();

    QString toString();

private:
    int m_n, m_m;
    double* A;

    int index( int n, int m ) const { return m + m_m * n; }

};

#endif // MATRIX_H
