namespace System.Diagnostics;

enum 405 "Change Log Entry Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Insertion") { Caption = 'Insertion'; }
    value(1; "Modification") { Caption = 'Modification'; }
    value(2; "Deletion") { Caption = 'Deletion'; }
}