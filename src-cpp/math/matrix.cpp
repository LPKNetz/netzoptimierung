#include "matrix.h"
#include <new>

Matrix::Matrix()
{
    this->m_m = 0;
    this->m_n = 0;
    A = nullptr;
}

Matrix::Matrix(int n, int m)
{
    this->m_m = m;
    this->m_n = n;
    //A = new double[n * m];
    A = (double*)malloc(sizeof (double) * n * m);
}

Matrix::Matrix(const Matrix &src)
{
    A = new double[src.m_n * src.m_m]();
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

Matrix::~Matrix()
{
    //delete[] A;
}

double Matrix::at(int n, int m)
{
    return A[index(n, m)];
}

void Matrix::fill(int n, int m, double a)
{
    A[index(n, m)] = a;
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
/**
 * Inverse of a Matrix
 * Gauss-Jordan Elimination
 * Originally written by https://github.com/peterabraham
 **/

    int i = 0;  // Zeilenindex
    int j = 0;  // Spaltenindex
    int k = 0;
    int n = 0;  // Zeilenanzahl
    double **mat = nullptr; // Matrix data
    double d = 0.0;

    n = this->m_n;

    // Allocating memory for matrix array
    mat = new double*[2*n];
    for (i = 0; i < 2*n; ++i)
    {
        mat[i] = new double[2*n]();
    }

    // Input matrix data
    for(i = 0; i < n; ++i)
    {
        for(j = 0; j < n; ++j)
        {
            mat[i][j] = this->at(j, j);
        }
    }

    // Initializing Right-hand side to identity matrix
    for(i = 0; i < n; ++i)
    {
        for(j = 0; j < 2*n; ++j)
        {
            if(j == (i+n))
            {
                mat[i][j] = 1;
            }
        }
    }

    // Partial pivoting
    for(i = n; i > 1; --i)
    {
        if(mat[i-1][1] < mat[i][1])
        {
            for(j = 0; j < 2*n; ++j)
            {
                d = mat[i][j];
                mat[i][j] = mat[i-1][j];
                mat[i-1][j] = d;
            }
        }
    }

    // Reducing To Diagonal Matrix
    for(i = 0; i < n; ++i)
    {
        for(j = 0; j < 2*n; ++j)
        {
            if(j != i)
            {
                d = mat[j][i] / mat[i][i];
                for(k = 0; k < n*2; ++k)
                {
                    mat[j][k] -= mat[i][k]*d;
                }
            }
        }
    }

    // Reducing To Unit Matrix
    for(i = 0; i < n; ++i)
    {
        d = mat[i][i];
        for(j = 0; j < 2*n; ++j)
        {
            mat[i][j] = mat[i][j]/d;
        }
    }

    // Inverse of the input matrix
    Matrix inv(n, n);

    for(i=0; i < n; ++i)
    {
        for(j = n; j < 2*n; ++j)
        {
            inv.A[index(i, j)] = mat[i][j];
        }
    }

    // Deleting the memory allocated
    for (i = 0; i < n; ++i)
    {
        //delete[] mat[i];
    }
    //delete[] mat;

    return inv;
}

QString Matrix::toString()
{
    QString res;
    for (int i=0; i < this->m_m; i++)
    {
        for (int j=0; j < this->m_n; j++)
        {
            res += QString().sprintf("%8.4lf\t", this->at(i, j));
        }
        res += "\n";
    }

    return res;
}
