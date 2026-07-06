namespace System.Threading;

enum 482 "Job Queue Report Output Type" implements "Job Queue Report Runner"
{
    Extensible = true;
    AssignmentCompatibility = true;
    DefaultImplementation = "Job Queue Report Runner" = "Job Queue Start Report Runner";

    value(4; "None (Processing only)") { Caption = 'None (Processing only)'; }
}