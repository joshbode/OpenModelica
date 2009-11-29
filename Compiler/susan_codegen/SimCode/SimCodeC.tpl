// This file defines templates for transforming an internal representation of a
// Modelica program to C code.
//
// When compiling a model the following files will be created:
//
// Model.cpp
// Model_functions.cpp
// Model_init.txt
// Model.makefile
//
// The following template functions generate the content of these files:
//
// cppFile
// functionsFile
// initFile
// makefile

spackage SimCodeC

typeview "SimCodeTV.mo"

// Root template for simulation "target"
translateModel(SimCode simCode) ::=
  case SIMCODE(modelInfo = MODELINFO) then
    # cppFileContent = cppFile(simCode)
    # textFile(cppFileContent, '<modelInfo.name>.cpp')
    //functionsFile(...)
    //initFile(...)
    //makefile(...)
    () // empty result

// Root template for function library "target"
//translateFunction(...) ::=
//    ...

cppFile(SimCode simCode) ::=
case SIMCODE(modelInfo = MODELINFO) then
<<
// Simulation code for <modelInfo.name> generated by the OpenModelica Compiler.

#include "modelica.h"
#include "assert.h"
#include "string.h"
#include "simulation_runtime.h"

#if defined(_MSC_VER) && !defined(_SIMULATION_RUNTIME_H)
  #define DLLExport   __declspec( dllexport )
#else 
  #define DLLExport /* nothing */
#endif 

#include "<modelInfo.name>_functions.cpp"

<globalData(modelInfo)>

<macros()>

<dataStructureFunctions()>

<outputComputationFunctions(nonStateContEquations, nonStateDiscEquations)>

<modelInputFunction(modelInfo)>

<modelOutputFunction(modelInfo)>

<residualStateComputation()>

<zeroCrossingFunctions()>

<whenFunction()>

<odeFunction(stateEquations)>

<initialFunction(initialEquations)>

<initialResidualFunction(residualEquations)>

<boundParametersFunction()>

<eventCheckingCode()>
>>

globalData(ModelInfo modelInfo) ::=
case MODELINFO(varInfo = VARINFO, vars = SIMVARS) then
<<
#define NHELP <varInfo.numHelpVars>
#define NG <varInfo.numZeroCrossings>
#define NX <varInfo.numStateVars>
#define NY <varInfo.numAlgVars>
#define NP <varInfo.numParams>
#define NO <varInfo.numOutVars>
#define NI <varInfo.numInVars>
#define NR <varInfo.numResiduals>
#define NEXT <varInfo.numExternalObjects>
#define MAXORD 5
#define NYSTR <varInfo.numStringAlgVars>
#define NPSTR <varInfo.numStringParamVars>

static DATA* localData = 0;
#define time localData-\>timeValue
extern "C" { /* adrpo: this is needed for Visual C++ compilation to work! */
  char *model_name="<name>";
  char *model_dir="<directory>";
}

<utilStaticStringArray("state_names", vars.stateVars)>
<utilStaticStringArray("derivative_names", vars.derivativeVars)>
<utilStaticStringArray("algvars_names", vars.algVars)>
<utilStaticStringArray("input_names", vars.inputVars)>
<utilStaticStringArray("output_names", vars.outputVars)>
<utilStaticStringArray("param_names", vars.paramVars)>
<utilStaticStringArray("string_alg_names", vars.stringAlgVars)>
<utilStaticStringArray("string_param_names", vars.stringParamVars)>

<utilStaticStringArrayComment("state_comments", vars.stateVars)>
<utilStaticStringArrayComment("derivative_comments", vars.derivativeVars)>
<utilStaticStringArrayComment("algvars_comments", vars.algVars)>
<utilStaticStringArrayComment("input_comments", vars.inputVars)>
<utilStaticStringArrayComment("output_comments", vars.outputVars)>
<utilStaticStringArrayComment("param_comments", vars.paramVars)>
<utilStaticStringArrayComment("string_alg_comments", vars.stringAlgVars)>
<utilStaticStringArrayComment("string_param_comments", vars.stringParamVars)>

<vars.stateVars of var as SIMVAR:
  '#define <cref(name)> localData-\>states[<var.index>]' "\n">
<vars.derivativeVars of var as SIMVAR:
  '#define <cref(name)> localData-\>statesDerivatives[<var.index>]' "\n">
<vars.algVars of var as SIMVAR:
  '#define <cref(name)> localData-\>algebraics[<var.index>]' "\n">
<vars.paramVars of var as SIMVAR:
  '#define <cref(name)> localData-\>parameters[<var.index>]' "\n">
<vars.extObjVars of var as SIMVAR:
  '#define <cref(name)> localData-\>extObjs[<var.index>]' "\n">

char* getName(double* ptr)
{
  <vars.stateVars of var as SIMVAR:
    'if (&<cref(name)> == ptr) return state_names[<var.index>];' "\n">
  <vars.derivativeVars of var as SIMVAR:
    'if (&<cref(name)> == ptr) return derivative_names[<var.index>];' "\n">
  <vars.algVars of var as SIMVAR:
    'if (&<cref(name)> == ptr) return algebraic_names[<var.index>];' "\n">
  <vars.paramVars of var as SIMVAR:
    'if (&<cref(name)> == ptr) return param_names[<var.index>];' "\n">
  return "";
}

static char init_fixed[NX+NX+NY+NP] = {
  <[(vars.stateVars of var as SIMVAR:
      '<boolToInt(var.isFixed)> /* <cref(origName)> */' ",\n"),
    (vars.derivativeVars of var as SIMVAR:
      '<boolToInt(var.isFixed)> /* <cref(origName)> */' ",\n"),
    (vars.algVars of var as SIMVAR:
      '<boolToInt(var.isFixed)> /* <cref(origName)> */' ",\n"),
    (vars.paramVars of var as SIMVAR:
      '<boolToInt(var.isFixed)> /* <cref(origName)> */' ",\n")] ",\n">
};

char var_attr[NX+NY+NP] = {
  <[(vars.stateVars of var as SIMVAR:
      '<typeAttrInt(type_)>+<discreteAttrInt(isDiscrete)> /* <cref(origName)> */' ",\n"),
    (vars.algVars of var as SIMVAR:
      '<typeAttrInt(type_)>+<discreteAttrInt(isDiscrete)> /* <cref(origName)> */' ",\n"),
    (vars.paramVars of var as SIMVAR:
      '<typeAttrInt(type_)>+<discreteAttrInt(isDiscrete)> /* <cref(origName)> */' ",\n")] ",\n">
};
>>

macros() ::=
<<
#define DIVISION(a,b,c) ((b != 0) ? a / b : a / division_error(b,c))

int encounteredDivisionByZero = 0;

double division_error(double b, const char* division_str)
{
  if(!encounteredDivisionByZero) {
    fprintf(stderr, "ERROR: Division by zero in partial equation: %s.\n",division_str);
    encounteredDivisionByZero = 1;
  }
  return b;
}
>>

dataStructureFunctions() ::=
<<
void setLocalData(DATA* data)
{
  localData = data;
}

DATA* initializeDataStruc(DATA_FLAGS flags)
{
  DATA* returnData = (DATA*)malloc(sizeof(DATA));

  if(!returnData) //error check
    return 0;

  memset(returnData,0,sizeof(DATA));
  returnData-\>nStates = NX;
  returnData-\>nAlgebraic = NY;
  returnData-\>nParameters = NP;
  returnData-\>nInputVars = NI;
  returnData-\>nOutputVars = NO;
  returnData-\>nZeroCrossing = NG;
  returnData-\>nInitialResiduals = NR;
  returnData-\>nHelpVars = NHELP;
  returnData-\>stringVariables.nParameters = NPSTR;
  returnData-\>stringVariables.nAlgebraic = NYSTR;

  if(flags & STATES && returnData-\>nStates) {
    returnData-\>states = (double*) malloc(sizeof(double)*returnData-\>nStates);
    returnData-\>oldStates = (double*) malloc(sizeof(double)*returnData-\>nStates);
    returnData-\>oldStates2 = (double*) malloc(sizeof(double)*returnData-\>nStates);
    assert(returnData-\>states&&returnData-\>oldStates&&returnData-\>oldStates2);
    memset(returnData-\>states,0,sizeof(double)*returnData-\>nStates);
    memset(returnData-\>oldStates,0,sizeof(double)*returnData-\>nStates);
    memset(returnData-\>oldStates2,0,sizeof(double)*returnData-\>nStates);
  } else {
    returnData-\>states = 0;
    returnData-\>oldStates = 0;
    returnData-\>oldStates2 = 0;
  }

  if(flags & STATESDERIVATIVES && returnData-\>nStates) {
    returnData-\>statesDerivatives = (double*) malloc(sizeof(double)*returnData-\>nStates);
    returnData-\>oldStatesDerivatives = (double*) malloc(sizeof(double)*returnData-\>nStates);
    returnData-\>oldStatesDerivatives2 = (double*) malloc(sizeof(double)*returnData-\>nStates);
    assert(returnData-\>statesDerivatives&&returnData-\>oldStatesDerivatives&&returnData-\>oldStatesDerivatives2);
    memset(returnData-\>statesDerivatives,0,sizeof(double)*returnData-\>nStates);
    memset(returnData-\>oldStatesDerivatives,0,sizeof(double)*returnData-\>nStates);
    memset(returnData-\>oldStatesDerivatives2,0,sizeof(double)*returnData-\>nStates);
  } else {
    returnData-\>statesDerivatives = 0;
    returnData-\>oldStatesDerivatives = 0;
    returnData-\>oldStatesDerivatives2 = 0;
  }

  if(flags & HELPVARS && returnData-\>nHelpVars) {
    returnData-\>helpVars = (double*) malloc(sizeof(double)*returnData-\>nHelpVars);
    assert(returnData-\>helpVars);
    memset(returnData-\>helpVars,0,sizeof(double)*returnData-\>nHelpVars);
  } else {
    returnData-\>helpVars = 0;
  }

  if(flags & ALGEBRAICS && returnData-\>nAlgebraic) {
    returnData-\>algebraics = (double*) malloc(sizeof(double)*returnData-\>nAlgebraic);
    returnData-\>oldAlgebraics = (double*) malloc(sizeof(double)*returnData-\>nAlgebraic);
    returnData-\>oldAlgebraics2 = (double*) malloc(sizeof(double)*returnData-\>nAlgebraic);
    assert(returnData-\>algebraics&&returnData-\>oldAlgebraics&&returnData-\>oldAlgebraics2);
    memset(returnData-\>algebraics,0,sizeof(double)*returnData-\>nAlgebraic);
    memset(returnData-\>oldAlgebraics,0,sizeof(double)*returnData-\>nAlgebraic);
    memset(returnData-\>oldAlgebraics2,0,sizeof(double)*returnData-\>nAlgebraic);
  } else {
    returnData-\>algebraics = 0;
    returnData-\>oldAlgebraics = 0;
    returnData-\>oldAlgebraics2 = 0;
    returnData-\>stringVariables.algebraics = 0;
  }

  if (flags & ALGEBRAICS && returnData-\>stringVariables.nAlgebraic) {
    returnData-\>stringVariables.algebraics = (char**)malloc(sizeof(char*)*returnData-\>stringVariables.nAlgebraic);
    assert(returnData-\>stringVariables.algebraics);
    memset(returnData-\>stringVariables.algebraics,0,sizeof(char*)*returnData-\>stringVariables.nAlgebraic);
  } else {
    returnData-\>stringVariables.algebraics=0;
  }

  if(flags & PARAMETERS && returnData-\>nParameters) {
    returnData-\>parameters = (double*) malloc(sizeof(double)*returnData-\>nParameters);
    assert(returnData-\>parameters);
    memset(returnData-\>parameters,0,sizeof(double)*returnData-\>nParameters);
  } else {
    returnData-\>parameters = 0;
  }

  if (flags & PARAMETERS && returnData-\>stringVariables.nParameters) {
  	  returnData-\>stringVariables.parameters = (char**)malloc(sizeof(char*)*returnData-\>stringVariables.nParameters);
      assert(returnData-\>stringVariables.parameters);
      memset(returnData-\>stringVariables.parameters,0,sizeof(char*)*returnData-\>stringVariables.nParameters);
  } else {
      returnData-\>stringVariables.parameters=0;
  }

  if(flags & OUTPUTVARS && returnData-\>nOutputVars) {
    returnData-\>outputVars = (double*) malloc(sizeof(double)*returnData-\>nOutputVars);
    assert(returnData-\>outputVars);
    memset(returnData-\>outputVars,0,sizeof(double)*returnData-\>nOutputVars);
  } else {
    returnData-\>outputVars = 0;
  }

  if(flags & INPUTVARS && returnData-\>nInputVars) {
    returnData-\>inputVars = (double*) malloc(sizeof(double)*returnData-\>nInputVars);
    assert(returnData-\>inputVars);
    memset(returnData-\>inputVars,0,sizeof(double)*returnData-\>nInputVars);
  } else {
    returnData-\>inputVars = 0;
  }

  if(flags & INITIALRESIDUALS && returnData-\>nInitialResiduals) {
    returnData-\>initialResiduals = (double*) malloc(sizeof(double)*returnData-\>nInitialResiduals);
    assert(returnData-\>initialResiduals);
    memset(returnData-\>initialResiduals,0,sizeof(double)*returnData-\>nInitialResiduals);
  } else {
    returnData-\>initialResiduals = 0;
  }

  if(flags & INITFIXED) {
    returnData-\>initFixed = init_fixed;
  } else {
    returnData-\>initFixed = 0;
  }

  /*   names   */
  if(flags & MODELNAME) {
    returnData-\>modelName = model_name;
  } else {
    returnData-\>modelName = 0;
  }
  
  if(flags & STATESNAMES) {
    returnData-\>statesNames = state_names;
  } else {
    returnData-\>statesNames = 0;
  }

  if(flags & STATESDERIVATIVESNAMES) {
    returnData-\>stateDerivativesNames = derivative_names;
  } else {
    returnData-\>stateDerivativesNames = 0;
  }

  if(flags & ALGEBRAICSNAMES) {
    returnData-\>algebraicsNames = algvars_names;
  } else {
    returnData-\>algebraicsNames = 0;
  }

  if(flags & PARAMETERSNAMES) {
    returnData-\>parametersNames = param_names;
  } else {
    returnData-\>parametersNames = 0;
  }

  if(flags & INPUTNAMES) {
    returnData-\>inputNames = input_names;
  } else {
    returnData-\>inputNames = 0;
  }

  if(flags & OUTPUTNAMES) {
    returnData-\>outputNames = output_names;
  } else {
    returnData-\>outputNames = 0;
  }

  /*   comments  */
  if(flags & STATESCOMMENTS) {
    returnData-\>statesComments = state_comments;
  } else {
    returnData-\>statesComments = 0;
  }

  if(flags & STATESDERIVATIVESCOMMENTS) {
    returnData-\>stateDerivativesComments = derivative_comments;
  } else {
    returnData-\>stateDerivativesComments = 0;
  }

  if(flags & ALGEBRAICSCOMMENTS) {
    returnData-\>algebraicsComments = algvars_comments;
  } else {
    returnData-\>algebraicsComments = 0;
  }

  if(flags & PARAMETERSCOMMENTS) {
    returnData-\>parametersComments = param_comments;
  } else {
    returnData-\>parametersComments = 0;
  }

  if(flags & INPUTCOMMENTS) {
    returnData-\>inputComments = input_comments;
  } else {
    returnData-\>inputComments = 0;
  }

  if(flags & OUTPUTCOMMENTS) {
    returnData-\>outputComments = output_comments;
  } else {
    returnData-\>outputComments = 0;
  }

  if (flags & EXTERNALVARS) {
    returnData-\>extObjs = (void**)malloc(sizeof(void*)*NEXT);
    if (!returnData-\>extObjs) {
      printf("error allocating external objects\n");
      exit(-2);
    }
    memset(returnData-\>extObjs,0,sizeof(void*)*NEXT);
    setLocalData(returnData); /* must be set since used by constructors*/
  }
  return returnData;
}

void deInitializeDataStruc(DATA* data, DATA_FLAGS flags)
{
  if(!data)
    return;

  if(flags & STATES && data-\>states) {
    free(data-\>states);
    data-\>states = 0;
  }

  if(flags & STATESDERIVATIVES && data-\>statesDerivatives) {
    free(data-\>statesDerivatives);
    data-\>statesDerivatives = 0;
  }

  if(flags & ALGEBRAICS && data-\>algebraics) {
    free(data-\>algebraics);
    data-\>algebraics = 0;
  }

  if(flags & PARAMETERS && data-\>parameters) {
    free(data-\>parameters);
    data-\>parameters = 0;
  }

  if(flags & OUTPUTVARS && data-\>inputVars) {
    free(data-\>inputVars);
    data-\>inputVars = 0;
  }

  if(flags & INPUTVARS && data-\>outputVars) {
    free(data-\>outputVars);
    data-\>outputVars = 0;
  }
  
  if(flags & INITIALRESIDUALS && data-\>initialResiduals){
    free(data-\>initialResiduals);
    data-\>initialResiduals = 0;
  }
  if (flags & EXTERNALVARS && data-\>extObjs) {
    free(data-\>extObjs);
    data-\>extObjs = 0;
  }
}
>>

outputComputationFunctions(list<Equation> cont, list<Equation> disc) ::=
# varDecls1 = ""
# body1 = (cont of eq: '<equation_(eq, varDecls1)>' "\n")
# varDecls2 = ""
# body2 = (disc of eq: '<equation_(eq, varDecls2)>' "\n")
<<
/* for continuous time variables */
int functionDAE_output()
{
  state mem_state;
  <varDecls1>

  mem_state = get_memory_state();
  <body1>
  restore_memory_state(mem_state);

  return 0;
}

/* for discrete time variables */
int functionDAE_output2()
{
  state mem_state;
  <varDecls2>

  mem_state = get_memory_state();
  <body2>
  restore_memory_state(mem_state);

  return 0;
}
>>

modelInputFunction(ModelInfo modelInfo) ::=
case MODELINFO(varInfo = VARINFO, vars = SIMVARS) then
<<
int input_function()
{
  <vars.inputVars of var as SIMVAR:
    '<cref(name)> = localData-\>inputVars[<i0>];' "\n">
  return 0;
}
>>

modelOutputFunction(ModelInfo modelInfo) ::=
case MODELINFO(varInfo = VARINFO, vars = SIMVARS) then
<<
int output_function()
{
  <vars.outputVars of var as SIMVAR:
    'localData-\>outputVars[<i0>] = <cref(name)>;' "\n">
  return 0;
}
>>

residualStateComputation() ::=
<<
int functionDAE_res(double *t, double *x, double *xd, double *delta,
                    long int *ires, double *rpar, long int* ipar)
{
  int i;
  double temp_xd[NX];
  double* statesBackup;
  double* statesDerivativesBackup;
  double timeBackup;

  statesBackup = localData-\>states;
  statesDerivativesBackup = localData-\>statesDerivatives;
  timeBackup = localData-\>timeValue;
  localData-\>states = x;

  for (i=0; i\<localData-\>nStates; i++) {
    temp_xd[i] = localData-\>statesDerivatives[i];
  }

  localData-\>statesDerivatives = temp_xd;
  localData-\>timeValue = *t;

  functionODE();

  /* get the difference between the temp_xd(=localData-\>statesDerivatives)
     and xd(=statesDerivativesBackup) */
  for (i=0; i \< localData-\>nStates; i++) {
    delta[i] = localData-\>statesDerivatives[i] - statesDerivativesBackup[i];
  }

  localData-\>states = statesBackup;
  localData-\>statesDerivatives = statesDerivativesBackup;
  localData-\>timeValue = timeBackup;

  if (modelErrorCode) {
    if (ires) {
      *ires = -1;
    }
    modelErrorCode =0;
  }

  return 0;
}
>>

zeroCrossingFunctions() ::=
<<
int function_zeroCrossing(long *neqm, double *t, double *x, long *ng,
                          double *gout, double *rpar, long* ipar)
{
  // TODO: Implement this
  fprintf(stderr, "ERROR: function_zeroCrossing not implemented\n");
  return 0;
}

int handleZeroCrossing(long index)
{
  // TODO: Implement this
  fprintf(stderr, "ERROR: handleZeroCrossing not implemented\n");
  return 0;
}

int function_updateDependents()
{
  // TODO: Implement this
  fprintf(stderr, "ERROR: function_updateDependents not implemented\n");
  return 0;
}
>>

whenFunction() ::=
<<
int function_when(int i)
{
  // TODO: Implement this
  fprintf(stderr, "ERROR: whenFunction not implemented\n");
  return 0;
}
>>

odeFunction(list<Equation> equations) ::=
# varDecls = ""
# body = (equations of eq: '<equation_(eq, varDecls)>' "\n")
<<
int functionODE()
{
  state mem_state;
  <varDecls>

  mem_state = get_memory_state();
  <body>
  restore_memory_state(mem_state);

  return 0;
}
>>

initialFunction(list<Equation> equations) ::=
# varDecls = ""
# body = (equations of eq as DAELow.SOLVED_EQUATION: '<equation_(eq, varDecls)>' "\n")
<<
int initial_function()
{
  state mem_state;
  <varDecls>

  mem_state = get_memory_state();
  <body>
  restore_memory_state(mem_state);

  return 0;
}
>>

initialResidualFunction(list<Equation> eqs) ::=
# varDecls = ""
# body = (
  eqs of eq as DAELow.RESIDUAL_EQUATION:
    if exp is DAE.SCONST then
      'localData-\>initialResiduals[i++] = 0;'
    else
      # preExp = ""
      # expPart = expression(exp, preExp, varDecls)
      '<preExp>localData-\>initialResiduals[i++] = <expPart>;'
  "\n"
)
<<
int initial_residual()
{
  int i = 0;
  state mem_state;
  <varDecls>

  mem_state = get_memory_state();
  <body>
  restore_memory_state(mem_state);

  return 0;
}
>>

boundParametersFunction() ::=
<<
int bound_parameters()
{
  // TODO: Implement this
  fprintf(stderr, "ERROR: boundParametersFunction not implemented\n");
  return 0;
}
>>

eventCheckingCode() ::=
<<
int checkForDiscreteVarChanges()
{
  int needToIterate = 0;
  
  for (long i = 0; i \< localData-\>nHelpVars; i++) {
    if (change(localData-\>helpVars[i])) {
      needToIterate=1;
    }
  }

  return needToIterate;
}
>>

//functionsFile() ::=
//<<
//#ifdef __cplusplus
//extern "C" {
//#endif
//
///* Header part */
///* End of header part */
//
///* Body */
///* End body */
//
//#ifdef __cplusplus
//}
//#endif
//>>
//
//initFile() ::=
//<<
//>>
//
//makefile() ::=
//<<
//>>

utilStaticStringArray(String name, list<SimVar> items) ::=
if items then
<<
char* <name>[<listLengthSimVar(items)>] = {<items of item as SIMVAR:
  '"<cref(origName)>"' ", ">};
>>
else
<<
char* <name>[1] = {""};
>>

utilStaticStringArrayComment(String name, list<SimVar> items) ::=
if items then
<<
char* <name>[<listLengthSimVar(items)>] = {<items of item as SIMVAR:
  '"<item.comment>"' ", ">};
>>
else
<<
char* <name>[1] = {""};
>>

equation_(Equation eq, Text varDecls) ::=
case SOLVED_EQUATION then
# preExp = ""
# expPart = expression(exp, preExp, varDecls)
<<
<preExp>
<cref(componentRef)> = <expPart>;
>>
case _ then
<<
notimplemented = notimplemented;
>>

boolToInt(Boolean) ::=
  case true  then "1"
  case false then "0"

// TODO: Correct type? Correct value?
typeAttrInt(DAE.ExpType) ::=
  case ET_REAL   then "1"
  case ET_STRING then "2"
  case ET_INT    then "4"
  case ET_BOOL   then "8"

discreteAttrInt(Boolean isDiscrete) ::=
  case true  then "16"
  case false then "0"

cref(ComponentRef) ::=
  case CREF_IDENT then ident

expType(DAE.ExpType) ::=
  case ET_INT    then "modelica_integer"
  case ET_REAL   then "modelica_real"
  case ET_BOOL   then "modelica_boolean"
  case ET_STRING then "modelica_string"
  case ET_COMPLEX(complexClassType = EXTERNAL_OBJ)  then "void *" 
  case ET_OTHER  then "modelica_complex"
  case ET_LIST
  case ET_METATUPLE
  case ET_METAOPTION
  case ET_UNIONTYPE
  case ET_POLYMORPHIC then "metamodelica_type"
  case ET_ARRAY then 
    match ty
    case ET_INT    then "integer_array"
    case ET_REAL   then "real_array"
    case ET_STRING then "string_array"
    case ET_BOOL   then "boolean_array"

expShortType(DAE.ExpType) ::=
  case ET_INT    then "integer"
  case ET_REAL   then "real"
  case ET_STRING then "string"
  case ET_BOOL   then "boolean"
  case ET_OTHER  then "complex"
  case ET_ARRAY then expShortType(ty)   
  case ET_COMPLEX then 'struct <name>'  
  
expTypeA(DAE.ExpType, Boolean isArray) ::=
  case ET_COMPLEX     then expShortType() // i.e. 'struct <name>'  
  case ET_LIST
  case ET_METATUPLE
  case ET_METAOPTION
  case ET_UNIONTYPE
  case ET_POLYMORPHIC then "metamodelica_type"

dotPath(Path) ::=
  case QUALIFIED      then '<name>.<dotPath(path)>'
  case IDENT          then name
  case FULLYQUALIFIED then dotPath(path)

underscorePath(Path) ::=
  case QUALIFIED      then '<System.stringReplace(name, "_", "__")>_<underscorePath(path)>'
  case IDENT          then System.stringReplace(name, "_", "__")
  case FULLYQUALIFIED then underscorePath(path)


recordDeclaration(RecordDeclaration) ::=
  case RECORD_DECL_FULL then <<
struct <name> {
  <variables of var as VARIABLE :
      if expType(ty) then '<it> <var.name>;'
      else '/* <var.name> is an odd member. */'
  \n>
};
<recordDefinition( dotPath(defPath),
                   underscorePath(defPath),
                   (variables of VARIABLE : '"<name>"' ",") )>
>> 
  case RECORD_DECL_DEF then 
    recordDefinition( dotPath(path),
                      underscorePath(path),
                      (fieldNames : '"<it>"' ",") )


recordDefinition(String origName, String encName, String fieldNames) ::=
<<
const char* <encName>__desc__fields[] = {<fieldNames>};
struct record_description <encName>__desc = {
  "<encName>", /* package_record__X */
  "<origName>", /* package.record_X */
  <encName>__desc__fields
};
>>


//!! assumes the type is T_ARRAY when array, so no branching by isArray here ... see Codegen.generateReturnDecl,
// ?? initopt dump ? see Codegen.tmpPrintInit usage in generateReturnDecl
functionHeader(String fname, Variables fargs, Variables outVars) ::=
<<
<outVars of VARIABLE : 
'#define <fname>_rettype_<i1> targ<i1>' 
\n>
typedef struct <fname>_rettype_s 
{
  <outVars of VARIABLE :
  '<expType(ty)> targ<i1>; /* <name><if ty is ET_ARRAY then '[<arrayDimensions : if it is SOME(d) then d else ":" ", ">]'> */'
  \n>
} <fname>_rettype;

DLLExport 
<fname>_rettype _<fname>(<fargs of VARIABLE : '<expType(ty)> <name>' ", ">);

DLLExport 
int in_<fname>(type_description * inArgs, type_description * outVar);
>>


functionsCpp(list<Function> functions, String fileNamePrefix) ::=
# funCpp =
<<
#ifdef __cplusplus
extern "C" {
#endif
/* header part */
<functions of FUNCTION : 
  <<
<recordDecls : recordDeclaration() \n>
<functionHeader(underscorePath(name), functionArguments, outVars)>
  >> 
\n> 
/* End of header part */

/* Body */
<functions : functionDef() \n>
/* End Body */

#ifdef __cplusplus
}
#endif

>>
# textFile(funCpp, '<fileNamePrefix>_functions.cpp')
() // an empty result, the same as ""

functionDef(Function) ::=
  case FUNCTION then
    # System.tmpTickReset(1)
    # fname = underscorePath(name)
    # retType = '<fname>_rettype'
    # varDecls = ""
    # retVar   = tempDecl(retType, varDecls)
    # stateVar = tempDecl("state", varDecls)
    # varDecls += variableDeclarations of VARIABLE : '<expType(ty)> <name>;<\n>'
    # bodyPart = (body of stmt : funStatement(stmt, varDecls) \n)
    <<
<retType> _<fname>(<functionArguments of VARIABLE : '<expType(ty)> <name>' ", ">)
{
  <varDecls>
  <stateVar> = get_memory_state();
  <bodyPart>
  
  _return:
  <outVars of VARIABLE :  
    '<retVar>.targ<i1> = <name>;'  
  \n>  
  restore_memory_state(<stateVar>);
  return <retVar>;
}
    >>
    

funBody(list<Statement> body) ::=
  # varDecls = ""
  # bodyPart = (body of stmt : funStatement(stmt, varDecls) \n)
<<
<varDecls>
<bodyPart>
>>


funStatement(Statement, Text varDecls) ::=
  case ALGORITHM then (statementLst : algStatement(it, varDecls) \n) 
  case BLOCK then ""


algStatement(DAE.Statement, Text varDecls) ::=
  case STMT_ASSIGN(exp1 = CREF(componentRef = WILD), exp = e) then
    # preExp = "" 
    # expPart = expression(e, preExp, varDecls)
    <<
<preExp>
<expPart>
    >>
  case STMT_ASSIGN(exp1 = CREF) then     
    # preExp = ""
    # expPart = expression(exp, preExp, varDecls)
    <<
<preExp>
<scalarLhsCref(exp1.componentRef)> = <expPart>;
    >>
  case STMT_IF then
    # preExp = ""
    # condExp = expression(exp, preExp, varDecls)
    <<
<preExp>
if(<condExp>) {
  <statementLst : algStatement(it, varDecls) \n>
}
<elseExpr(else_, varDecls)>
    >>
  case STMT_FOR(exp = rng as RANGE) then
    # stateVar = tempDecl("state", varDecls)
    # dvar = System.tmpTick() // a hack to be precisely the same as original ... see Codegen.generateAlgorithmStatement case FOR
    # identType = expTypeA(type_, boolean)
    # r1 = tempDecl(identType, varDecls)
    # r2 = tempDecl(identType, varDecls)
    # r3 = tempDecl(identType, varDecls)
    # preExp = ""
    # er1 = expression(rng.exp, preExp, varDecls)
    # er2 = if rng.expOption is SOME(eo) 
            then expression(eo, preExp, varDecls)
            else "(1)"
    # er3 = expression(rng.range, preExp, varDecls) 
    <<
<preExp>
<r1> = <er1>; <r2> = <er2>; <r3> = <er3>;
{
<identType> <ident>;

  for (<ident> = <r1>; in_range_<expShortType(type_)>(<ident>, <r1>, <r3>); <ident> += <r2>) {
    <stateVar> = get_memory_state();
    <statementLst : algStatement(it, varDecls) \n /* ??CONTEXT(codeContext,expContext,IN_FOR_LOOP(loopContext)*/ >
    restore_memory_state(<stateVar>);
  }
} /*end for*/
    >>

    
elseExpr(DAE.Else, Text varDecls) ::= 
  case NOELSE then ()
  case ELSEIF then
    # preExp = ""
    # condExp = expression(exp, preExp, varDecls)
    <<
else {
<preExp>
if(<condExp>)) {
  <statementLst : algStatement(it, varDecls) \n>
}
<elseExpr(else_, varDecls)>
}
    >>
  case ELSE then
    <<
else {
  <statementLst : algStatement(it, varDecls) \n>
}
    >>

scalarLhsCref(ComponentRef) ::=
  case CREF_IDENT then ident
  case CREF_QUAL  then '<ident>.<scalarLhsCref(componentRef)>'

//TODO: this wrong for qualified integers !
rhsCref(ComponentRef, Type ty) ::=
<<
<if ty is INT then
"(modelica_integer)"
><
  case CREF_IDENT then ident
  case CREF_QUAL then '<ident>.<rhsCref(componentRef,ty)>'
>
>>
  
      
expression(Exp, Text preExp, Text varDecls) ::=
  case ICONST then integer
  case RCONST then real
  case SCONST then
    # strVar = tempDecl("modelica_string", varDecls)
    # preExp += 'init_modelica_string(&<strVar>,"<Util.escapeModelicaStringToCString(string)>");<\n>'
    strVar  
  case BCONST then  if bool then "(1)" else "(0)"
  case CREF   then rhsCref(componentRef, ty)
  case BINARY then ( //binaryExpression(operator, exp1, exp2, preExp, varDecls)
	  # e1 = expression(exp1, preExp, varDecls)
	  # e2 = expression(exp2, preExp, varDecls)
	  match operator
	  case ADD(ty = STRING) then
	    # tmpStr = tempDecl("modelica_string", varDecls)
	    # preExp += 'cat_modelica_string(&<tmpStr>,&<e1>,&<e2>);<\n>'
	    tmpStr
	  case ADD then '(<e1> + <e2>)'
	  case SUB then '(<e1> - <e2>)'
	  case MUL then '(<e1> * <e2>)'
	  case DIV then '(<e1> / <e2>)'
	  case POW then 'pow((modelica_real)<e1>, (modelica_real)<e2>)'
	  case UMINUS then () //# error
	  case UPLUS then () //# error
  )
  case RELATION then (
      # e1 = expression(exp1, preExp, varDecls)
	  # e2 = expression(exp2, preExp, varDecls)
	  match operator
	  case LESS(ty = BOOL) then '(!<e1> && <e2>)'
	  case LESS(ty = STRING) then "# string comparison not supported\n"
	  case LESS(ty = INT)  then '(<e1> \< <e2>)'
	  case LESS(ty = REAL) then '(<e1> \< <e2>)'
	  
	  case GREATER(ty = BOOL) then '(<e1> && !<e2>)'
	  case GREATER(ty = STRING) then "# string comparison not supported\n"
	  case GREATER(ty = INT)  then '(<e1> > <e2>)'
	  case GREATER(ty = REAL) then '(<e1> > <e2>)'
	  
	  case LESSEQ(ty = BOOL) then '(!<e1> || <e2>)'
	  case LESSEQ(ty = STRING) then "# string comparison not supported\n"
	  case LESSEQ(ty = INT)  then '(<e1> \<= <e2>)'
	  case LESSEQ(ty = REAL) then '(<e1> \<= <e2>)'
	  
	  case GREATEREQ(ty = BOOL) then '(<e1> || !<e2>)'
	  case GREATEREQ(ty = STRING) then "# string comparison not supported\n"
	  case GREATEREQ(ty = INT)  then '(<e1> >= <e2>)'
	  case GREATEREQ(ty = REAL) then '(<e1> >= <e2>)'
	  
	  case EQUAL(ty = BOOL)   then '((!<e1> && !<e2>) || (<e1> && <e2>))'
	  case EQUAL(ty = STRING) then '(!strcmp(<e1>,<e2>))'
	  case EQUAL(ty = INT)    then '(<e1> == <e2>)'
	  case EQUAL(ty = REAL)   then '(<e1> == <e2>)'
	  
	  case NEQUAL(ty = BOOL)   then '((!<e1> && <e2>) || (<e1> && !<e2>))'
	  case NEQUAL(ty = STRING) then '(strcmp(<e1>,<e2>))'
	  case NEQUAL(ty = INT)    then '(<e1> != <e2>)'
	  case NEQUAL(ty = REAL)   then '(<e1> != <e2>)'
  )
  case IFEXP then
    # eCond = expression(expCond, preExp, varDecls)
	# tmpB = tempDecl("modelica_boolean", varDecls)
    # preExpThen = ""
	# eThen = expression(expThen, preExpThen, varDecls)
    # preExpElse = ""
	# eElse = expression(expElse, preExpElse, varDecls)
	# preExp +=  
	  <<
<tmpB> = <eCond>;
if(<tmpB>) {
  <preExpThen>
}
else {
  <preExpElse>
}<\n>
      >>
	<<
((<tmpB>)?<eThen>:<eElse>)
    >>
  case CAST(ty = INT)  then '((modelica_int)<expression(exp, preExp, varDecls)>)'
  case CAST(ty = REAL) then '((modelica_real)<expression(exp, preExp, varDecls)>)'    
  case _ then "#non-template-implemented expression#"  
  
tempDecl(String ty, Text varDecls) ::=
  # newVar = 'tmp<System.tmpTick()>'
  # varDecls += '<ty> <newVar>;<\n>'
  newVar

end SimCodeC;
// vim: syntax=susan sw=2 sts=2
