#include "matrix.h"

Matrix::Matrix(int n, int m)
{
    this->m_m = m;
    this->m_n = n;
    A = new double[n * m];
}

Matrix::Matrix(const Matrix &src)
{
    A = new double[src.m_n * src.m_m];
    this->m_m = src.m_m;
    this->m_n = src.m_n;

    for (int m=0; m<src.m_m; m++)
    {
        for (int n=0; n<src.m_n; n++)
        {
            A[index(n, m)] = src.A[index(n, m)];
        }
    }
}

double Matrix::at(int n, int m)
{
    return A[index(n, m)];
}

Matrix Matrix::operator+(const Matrix &rhs)
{
    if (this->m_m != rhs.m_m || this->m_n != rhs.m_n)
        return Matrix (0, 0);

    Matrix M(this->m_n, this->m_m);

    for (int m=0; m<this->m_m; m++)
    {
        for (int n=0; n<this->m_n; n++)
        {
            M.A[index(n, m)] = this->A[index(n, m)] + rhs.A[index(n, m)];
        }
    }

    return M;
}

Matrix Matrix::operator-(const Matrix &rhs)
{
    if (this->m_m != rhs.m_m || this->m_n != rhs.m_n)
        return Matrix (0, 0);

    Matrix M(this->m_n, this->m_m);

    for (int m=0; m<this->m_m; m++)
    {
        for (int n=0; n<this->m_n; n++)
        {
            M.A[index(n, m)] = this->A[index(n, m)] - rhs.A[index(n, m)];
        }
    }

    return M;
}

Matrix Matrix::operator*(Matrix rhs)
{
    if (this->m_m != rhs.m_n)
        return Matrix (0, 0);

    Matrix M(rhs.m_n, this->m_m);

    for (int n=0; n<this->m_n; n++)
    {
        for (int m=0; m<rhs.m_m; m++)
        {
            double r = 0.0;

            for (int i=0; i<rhs.m_n; i++)
            {
                r += this->at(n,i) * rhs.at(i,n);
            }

            M.A[index(n, m)] = r;
        }
    }

    return M;
}

Matrix Matrix::invert()
{

}
