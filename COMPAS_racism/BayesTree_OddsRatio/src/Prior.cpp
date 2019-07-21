//extern "C" {
#include <R.h>
#include <Rmath.h>
//};


#include "global.h"
#include "List.h"
#include "Node.h"
#include "Rlob.h"
#include "Funs.h"
#include "Likelihood.h"


typedef Node *NodeP;


int SumGoodVar(Node *n)
{
	int sum = 0;
	int i;
	for(i=1;i<=NumX;i++) sum += (n->VarAvail)[i];
	return sum;
}


void GetSplitInterval(int *LeftI, int *RightI, Node *curr,int VarI)
// get interval of available splits for ordered variable
// curr is node, VarI is index of variables, LeftI and RightI give the interval (indices)
{
	
	// make sure the variable is ordered
	if(!(VarType[VarI]==ORD)) {
		Rprintf("error in GetSplitInterval: variable not ordered\n");
	} else {

	int Lfound=0;// flag to keep track if you have found LeftI
	int Rfound=0;// flag to keep track if you have found RightI
	*LeftI = 1; // right value if you top out
	*RightI = RuleNum[VarI]; // right value if you top out
	int Right;
	
	// move up tree until you have topped out or found both left and right
	while((!(curr->Top)) && (!(Lfound && Rfound))) {

		if(curr == (curr->Parent)->RightC) {
			Right = 1;
		} else {
			Right = 0;
		}

		curr = curr->Parent;
		
		//if you find the variable set the left or right
		if((curr->rule).Var==VarI) {
			if(Right && (!Lfound)) {
				Lfound = 1;
				*LeftI = (curr->rule).OrdRule + 1;
			}
			if((!Right) && (!Rfound)) {
				Rfound = 1;
				*RightI = (curr->rule).OrdRule - 1;
			}
		}
	}
	}
}


void GetSetCats(Node *curr,int VarI, int *cats)

{
	int i;
	Node *dad;

	if(!(VarType[VarI]==CAT)) Rprintf("error in GetSetCats: not a CAT variable\n");
	

	int NR = RuleNum[VarI];
	for(i=1;i<=NR;i++) cats[i]=1;

	while(!(curr->Top)) {
		dad = curr->Parent;
		if((dad->rule).Var == VarI) {
			if(curr==(dad->LeftC)) {
				for(i=1;i<=NR;i++) {
					if((dad->rule).CatRule[i]) cats[i]=0;
				}
			} else {
				for(i=1;i<=NR;i++) {
					if(!((dad->rule).CatRule[i])) cats[i]=0;
				}
			}
		}
		curr = dad;
	}
}



double PGrow(Node *n)
{

	double alpha,beta;

	alpha=PriParams.base;
	beta=PriParams.power;
	
	int Ngood = SumGoodVar(n);
	if(Ngood) {
		int nobs = (n->DataList).length;
		if(nobs<5) {
			return .001*alpha/(pow(1.0+Depth(n),beta));
		} else {
			//return .9;
			return alpha/(pow(1.0+Depth(n),beta));
		}
	} else {
		return 0;
	}
}






int SpawnChildren(Node *n,int LeftEx,int RightEx)
{
	if(!(n->rule).Var) {
		Rprintf("error in SpawnChildren: rule not set\n");
		return -1;
	}

	int i;

	n->Bot = 0;
	n->Nog = 1;
	if(!(n->Top)) (n->Parent)->Nog=0;

	n->LeftC = new Node;
	n->RightC = new Node;

	(n->LeftC)->Top=0;
	(n->LeftC)->Bot=1;
	(n->LeftC)->Nog=0;
	(n->LeftC)->Parent = n;
	
	for(i=1;i<=NumX;i++) ((n->LeftC)->VarAvail)[i] = (n->VarAvail)[i];
	if(LeftEx) ((n->LeftC)->VarAvail)[(n->rule).Var]=0;


	(n->RightC)->Top=0;
	(n->RightC)->Bot=1;
	(n->RightC)->Nog=0;
	(n->RightC)->Parent = n;

	for(i=1;i<=NumX;i++) ((n->RightC)->VarAvail)[i] = (n->VarAvail)[i];
	if(RightEx) ((n->RightC)->VarAvail)[(n->rule).Var]=0;

	AddDatChildren(n);

	return 1;
}

int GetSkipBadInd(int n,int *vec,int ind)
{
	int ii=0;
	int i;
	for(i=1;i<=n;i++) {
		if(vec[i]) {
			ii+=1;
			if(ii==ind) return i;
		}
	}

	return 0;
}


int DrPriVar(Node *n)
// returns index of variable to split on
{
	int Ngood = SumGoodVar(n);
	//double u=ran1(&idum);
	double u= unif_rand();
	int VarI =  (int)floor(u*Ngood)+1;

	return GetSkipBadInd(NumX,n->VarAvail,VarI);


	
}

void DrPriRule(int VarI,Node *GNode,int *LeftEx,int *RightEx)
//
{

	
	*LeftEx = 0;
	*RightEx = 0;

	int i;

	int LeftI,RightI;
	
	double u;

	int numsplit;

	int *cats;
	int Ncat;


	int NR;
	int selind;
	int NRcats;
	

	if(VarType[VarI]==CAT) {
		NR = RuleNum[VarI];
		cats = new int [NR+1];
		(GNode->rule).CatRule = new int [NR+1];
		GetSetCats(GNode, VarI,cats);
		Ncat=0;
		for(i=1;i<=NR;i++) Ncat += cats[i];
		if(Ncat<2) {
			Rprintf("error in DrPriRule: less than 2 values left for cat var\n");
			delete [] cats;
		
		}


		int *sel = new int [Ncat+1];
		sel[1] = 1;// the first value of cats always goes right
		//int index =(int)(ran1(&idum)*(pow(2.0,Ncat-1)-1));
		int index =(int)(unif_rand()*(pow(2.0,Ncat-1)-1));
		indtd(Ncat-1,index,(sel+1));
		
		selind=0;
		for(i=1;i<=NR;i++) {
			if(cats[i]) {
				selind += 1;
				(GNode->rule).CatRule[i]=sel[selind];
			} else {
				(GNode->rule).CatRule[i]=Bern(.5); // Hugh
			}
		}


	

		NRcats=0;
		for(i=1;i<=Ncat;i++) NRcats += sel[i];


		if((Ncat-NRcats)==1) *LeftEx=1;
		if(NRcats==1) *RightEx=1;


		delete [] sel;
		delete [] cats;

	} else {
		GetSplitInterval(&LeftI,&RightI,GNode,VarI);
		numsplit = RightI-LeftI+1;
		if(numsplit ==0) {
			Rprintf("error in DrPriRule: no splits left for ordered var\n");
			
		}
		
		//u = ran1(&idum);
		u = unif_rand();
		(GNode->rule).OrdRule = LeftI +((int)floor(u*numsplit));

		if((GNode->rule).OrdRule==LeftI) *LeftEx=1;
		if((GNode->rule).OrdRule==RightI) *RightEx=1;

	}

	(GNode->rule).Var=VarI;

}

int MaxDepth(Node *top)
{

	int nbot;
	NodeP *botvec;
	MakeBotVec(top,&botvec,&nbot);

	int max=0;
	int dep;
	int i;
	for(i=1;i<=nbot;i++) {
		dep=Depth(botvec[i]);
		if(dep>max) max=dep;
	}

	delete [] botvec;
	return max;
}



void DrawPrior(Node *n)
{
	int LeftEx,RightEx;
	int VarI;

	if(Bern(PGrow(n))) {
		VarI = DrPriVar(n);//draw variable
		if(VarI) {
			DrPriRule(VarI,n,&LeftEx,&RightEx);//draw rule
			SpawnChildren(n,LeftEx,RightEx); //create children
			DrawPrior(n->LeftC);
			DrawPrior(n->RightC);
		} 
	}
}



double LogPriT(Node *n)
{

	double pgrow = PGrow(n);

	double retval;
	int VarI;

	int Ncat;
	int *cats;

	int LeftI,RightI;

	int NR,i;


	if(n->Bot) {
		retval = log(1.0-pgrow);
	} else {
		retval = log(pgrow);
		retval -= log((double)SumGoodVar(n));
		VarI = (n->rule).Var;
		if(VarType[VarI]==CAT) {

			NR = RuleNum[VarI];
			cats = new int [NR+1];
			GetSetCats(n, VarI,cats);
			Ncat=0;
			for(i=1;i<=NR;i++) Ncat += cats[i];

			retval -= log(pow(2.0,Ncat-1)-1.0);
			retval -= log(pow(2.0,NR-Ncat)); //Hugh

			delete [] cats;
		} else {
			GetSplitInterval(&LeftI,&RightI,n,VarI);
			retval -= log((double)(RightI-LeftI+1));
		}

		retval = retval + LogPriT(n->LeftC) + LogPriT(n->RightC);
	}

	return retval;

}
