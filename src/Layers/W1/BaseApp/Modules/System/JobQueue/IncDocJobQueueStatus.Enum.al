namespace System.Threading;

enum 487 "Inc. Doc. Job Queue Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Scheduled") { Caption = 'Scheduled'; }
    value(2; "Error") { Caption = 'Error'; }
    value(3; "Processing") { Caption = 'Processing'; }
}