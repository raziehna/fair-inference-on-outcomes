#ifndef GUARD_MuS
#define GUARD_MuS

#include "Lib.h"
#include "EndNodeModel.h"

class MuS: public EndNodeModel
{
public:
   // construct and destruct----------------------------------
   MuS():
      mu(0.0),                  //parameter
      sigma2(1.0),                //other parameter
      a(1.0),                   //prior
      nob(0),y(0),indices(0)    //data
      {}
   ~MuS() {}
   // get,set---------------------------------------
   void setMu(double mu) {this->mu = mu;}
   void setSigma(double s) {this->sigma2=s*s;clearData();}
   //void setSigma(double s) {this->sigma2=s*s;updatepost();}
   void setPriorS(double s) {a=(1.0/(s*s));clearData();}
   //void setPriorS(double s) {a=(1.0/(s*s));updatepost();}
   double getMu() {return mu;}
   double getSigma2() { return sigma2;}
   double getA() { return a;}
   // EndNodeModel ---------------------------------
   virtual int getEstimateDim() const {return 1;}
   virtual double* getParameterEstimate(); 
   virtual double* getFits(int np, double** xpred, int* indpred);
   virtual double getLogILik();
   virtual void setData(int nob, double **x, double *y,
                        int *indices, double *w); 
   // public methods -----------------------------
   void toScreen() const;
   void drawPost();
   void clearData() {nob=0;y=0;indices=0;updatepost();}
private:
   //parameter // xi ~ N(mu,sig2)---
   double mu;  
   // other------------
   double sigma2;
   // prior------------- mu ~ N(0,1/a) , prior
   double a;
   // data --------------------------
   int nob;
   double* y;
   //double* w; should implement this in the future
   int* indices;
   // state -----------------------------
   double post_m;
   double post_s;
   double ybar,s2; // sample mean and sum(y_i-ybar)^2
   double b;     // nob/sigma2
   // methods----------------------------------------------
   void updatepost();
};
#endif
