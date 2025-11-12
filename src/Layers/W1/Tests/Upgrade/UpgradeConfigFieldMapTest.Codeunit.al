#if not CLEAN26
codeunit 135974 "Upgrade Config. Field Map Test"
{
    Subtype = Test;
    ObsoleteState = Pending;
    ObsoleteReason = 'The table Config. Field Map deleted in version 26.0'; 
    ObsoleteTag = '26.0';

    [Test]
    procedure ConfigFieldMappingToConfigFieldMapTest()
    begin
    end;
}
#endif