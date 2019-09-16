#include "matrix.h"
#include <new>
#include <vector>
#include <cmath>

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
    //printf("Matrix n=%i m=%i\n", n, m);
    A = new double[n * m]();
    //A = (double*)malloc(sizeof (double) * n * m);
}

Matrix::Matrix(const Matrix &src)
{
    //printf("Copy Matrix n=%i m=%i\n", src.m_n, src.m_m);
    A = new double[src.m_n * src.m_m]();
    //A = (double*)malloc(sizeof (double) * src.m_n * src.m_m);
    this->m_m = src.m_m;
    this->m_n = src.m_n;

    for (int m=0; m<src.m_m; m++)
    {
        for (int n=0; n<src.m_n; n++)
        {
            A[index(n, m)] = src.A[index(n, m)];
            //this->fill(n, m, src.A[index(n, m)]);
        }
    }
}

Matrix::~Matrix()
{
    //printf("Matrix destructor\n");
    delete[] A;
}

double Matrix::at(int n, int m)
{
    if ((n < 0) || (m < 0) || (n >= this->m_n) || (m >= this->m_m))
    {
        printf("Matrix index out of bounds in method at\n");
        return -1.11;
    }

    return A[index(n, m)];
}

void Matrix::fill(int n, int m, double a)
{
    if ((n < 0) || (m < 0) || (n >= this->m_n) || (m >= this->m_m))
    {
        printf("Matrix index out of bounds in method fill\n");
        return;
    }

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

    Matrix M(this->m_n, rhs.m_m);

    for (int n=0; n<this->m_n; n++)
    {
        for (int m=0; m<rhs.m_m; m++)
        {
            double r = 0.0;

            for (int i=0; i<rhs.m_n; i++)
            {
                r += this->at(n,i) * rhs.at(i,m);
            }

            M.fill(n, m, r);
        }
    }

    return M;
}

Matrix Matrix::operator=(const Matrix &rhs)
{
    if ((this->m_m != rhs.m_m) || (this->m_n != rhs.m_n))
    {
        delete[] A;
        this->m_m = rhs.m_m;
        this->m_n = rhs.m_n;
        A = new double[rhs.m_n * rhs.m_m]();
    }

    for (int m=0; m<rhs.m_m; m++)
    {
        for (int n=0; n<rhs.m_n; n++)
        {
            A[index(n, m)] = rhs.A[index(n, m)];
        }
    }

    return *this;
}

Matrix Matrix::invert()
{
/**
 * Inverse of a Matrix
 * Gauss-Jordan Elimination
 * Originally written by https://martin-thoma.com/inverting-matrices/
 **/

    //printf("Matrix invert\n");

    unsigned long n = unsigned(this->m_n);

    std::vector<double> line(2*n,0.0);
    std::vector< std::vector<double> > A(n,line);

    // Read input data
    for (unsigned long i=0; i<n; i++) {
        for (unsigned long j=0; j<n; j++) {
            A[i][j] = this->at(int(i), int(j));
        }
    }

    for (unsigned long i=0; i<n; i++) {
            A[i][n+i] = 1.0;
        }

    for (unsigned long i=0; i<n; i++) {
        // Search for maximum in this column
        double maxEl = abs(A[i][i]);
        unsigned long maxRow = i;
        for (unsigned long k=i+1; k<n; k++) {
            if (abs(A[k][i]) > maxEl) {
                maxEl = A[k][i];
                maxRow = k;
            }
        }

        // Swap maximum row with current row (column by column)
        for (unsigned long k=i; k<2*n;k++) {
            double tmp = A[maxRow][k];
            A[maxRow][k] = A[i][k];
            A[i][k] = tmp;
        }

        // Make all rows below this one 0 in current column
        for (unsigned long k=i+1; k<n; k++) {
            double c = -A[k][i]/A[i][i];
            for (unsigned long j=i; j<2*n; j++) {
                if (i==j) {
                    A[k][j] = 0.0;
                } else {
                    A[k][j] += c * A[i][j];
                }
            }
        }
    }

    // Solve equation Ax=b for an upper triangular matrix A
    for (signed long ii=long(n)-1; ii>=0; ii--) {
        unsigned long i = unsigned(ii);
        for (unsigned long k=n; k<2*n;k++) {
            A[i][k] /= A[i][i];
        }
        // this is not necessary, but the output looks nicer:
        //A[i][i] = 1.0;

        for (signed long tmp_rowModify=long(i)-1;tmp_rowModify>=0; tmp_rowModify--) {
            unsigned long rowModify = unsigned(tmp_rowModify);
            for (unsigned long columModify=n;columModify<2*n;columModify++) {
                A[rowModify][columModify] -= A[i][columModify]
                                             * A[rowModify][i];
            }
            // this is not necessary, but the output looks nicer:
            //A[rowModify][i] = 0;
        }
    }

    // Write output data
    Matrix inv(this->m_n, this->m_m);
    for (unsigned long i=0; i<n; i++) {
        for (unsigned long j=0; j<n; j++) {
            inv.fill(int(i), int(j), A[i][n+j]);
        }
    }

    return inv;
}

QString Matrix::toString()
{
    QString res = "\n";
    for (int i=0; i < this->m_n; i++)
    {
        for (int j=0; j < this->m_m; j++)
        {
            res += QString().sprintf("%17.15lf\t", this->at(i, j));
        }
        res += "\n";
    }

    return res;
}
