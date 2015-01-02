#include <cstdio>
#include <fstream>
#include <iostream>
#include <zlib.h>
#include <libgen.h>      

#include "TTree.h"
#include "TFile.h"
#include "TSystem.h"
#include "TTreeIndex.h"
#include "TMath.h"

#include "Adu5Pat.h"
#include "RawAnitaHeader.h"

#include <map>

using namespace std;

void makeGpsEventTree(char *inName, char *headName, char *outName);


int main(int argc, char **argv) {
  if(argc<3) {
    std::cout << "Usage: " << basename(argv[0]) << " <inhkfile> <inheadfile> <outhkfile>" << std::endl;
    return -1;
  }
  makeGpsEventTree(argv[1],argv[2],argv[3]);
  return 0;
}


void makeGpsEventTree(char *inName,char *headName, char *outName) {

  Adu5Pat *patPtr=0;
  RawAnitaHeader *headPtr=0;

   TFile *fpIn = new TFile(inName);
   if(!fpIn) {
      std::cerr << "Couldn't open " << inName << "\n";
      return;
   }  
   TTree *adu5PatTree = (TTree*) fpIn->Get("adu5PatTree");
   if(!adu5PatTree) {
      std::cerr << "Couldn't get hkTree from " << inName << "\n";
      return;
   }      
   TTree *adu5bPatTree = (TTree*) fpIn->Get("adu5bPatTree");
   if(!adu5bPatTree) {
      std::cerr << "Couldn't get hkTree from " << inName << "\n";
      return;
   }      
   adu5PatTree->SetBranchAddress("pat",&patPtr);   
   adu5bPatTree->SetBranchAddress("pat",&patPtr);   
   TFile *fpHead = new TFile(headName);
   if(!fpHead) {
      std::cerr << "Couldn't open " << headName << "\n";
      return;
   }  
   TTree *headTree = (TTree*) fpHead->Get("headTree");
   if(!headTree) {
      std::cerr << "Couldn't get headTree from " << headName << "\n";
      return;
   }      
   headTree->SetBranchAddress("header",&headPtr);
      

   TFile *fpOut = new TFile(outName,"RECREATE");
   TTree *adu5PatTreeInt = new TTree("adu5PatTree","Tree of ADU5 PAT");
   Adu5Pat *thePat = new Adu5Pat();
   adu5PatTreeInt->Branch("pat","Adu5Pat",&thePat);

   Long64_t headEntries = headTree->GetEntries();
   Long64_t nentries = adu5PatTree->GetEntries();
   adu5PatTree->BuildIndex("realTime","payloadTimeUs");

   Long64_t nbytes = 0, nb = 0;
   Int_t intFlag;

   std::map<Long64_t,Int_t> adu5PatEntryMap;
   for(int entry=0;entry<nentries;entry++) {
     adu5PatTree->GetEntry(entry);
     if(patPtr->attFlag==0) {
       Long64_t fakeTime=patPtr->realTime;
       adu5PatEntryMap.insert(std::pair<Long64_t,Int_t>(fakeTime , entry)  );
     }
   }
   
   std::cout << "adu5PatEntryMap.size(): "<< adu5PatEntryMap.size() << "\n";

   std::map<Long64_t,Int_t>::iterator patLowIt; 
   std::map<Long64_t,Int_t>::iterator patUpIt; 

   for (Long64_t jentry=0; jentry<headEntries;jentry++) {
      if(jentry%10000==0) cerr << "*";
      nb = headTree->GetEntry(jentry);   nbytes += nb;
     

      Long64_t triggerTime=headPtr->triggerTime;
      patLowIt=adu5PatEntryMap.lower_bound(triggerTime);
      patUpIt=adu5PatEntryMap.upper_bound(triggerTime);
 
      std::cout << triggerTime << "\t" << patLowIt->first << "\t" << patUpIt->first << "\t" 
		<< patLowIt->second << "\t" << patUpIt->second << "\n";       
      adu5PatTree->GetEntry(patLowIt->second);


      intFlag=headPtr->triggerTime-patPtr->realTime;

      if(thePat) delete thePat;
      thePat = new Adu5Pat(*patPtr);
      thePat->intFlag=intFlag;
      adu5PatTreeInt->Fill();

   }
   adu5PatTreeInt->AutoSave();
   fpOut->Close();
   cerr << endl;
}
