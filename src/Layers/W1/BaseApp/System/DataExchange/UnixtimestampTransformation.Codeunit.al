#if not CLEAN25

namespace System.IO;

codeunit 1225 "Unixtimestamp Transformation"
{
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';
    ObsoleteReason = 'Replaced by Unixtimestamp enum value in enum 1237 "Transformation Rule Type" implements "Transformation Rule"';

    var
        UNIXTimeStampTxt: Label 'UNIXTIMESTAMP', Locked = true;

    [Obsolete('Replaced by interface "Transformation Rule"', '25.0')]
    procedure GetUnixTimestampCode(): Code[20]
    begin
        exit(UNIXTimeStampTxt);
    end;
}

#endif