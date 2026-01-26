table 139145 "SEPA CAMT File Parameters"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Encoding; Text[30])
        {
        }
        field(2; StmtDateFieldValue; Text[30])
        {
        }
        field(3; IBANFieldValue; Text[50])
        {
        }
        field(4; BankAccountNoFieldValue; Text[30])
        {
        }
        field(5; ClsBalFieldValue; Text[30])
        {
        }
        field(6; CcyFieldValue; Text[30])
        {
        }
        field(7; CrdtFieldValue; Text[30])
        {
        }
        field(8; DbitFieldValue; Text[30])
        {
        }
        field(9; BalCrdtDbtFieldValue; Text[30])
        {
        }
        field(10; CrdtDateFieldValue; Text[30])
        {
        }
        field(11; DbitDateFieldValue; Text[30])
        {
        }
        field(12; CrdtTextFieldValue; Text[30])
        {
        }
        field(13; DbitTextFieldValue; Text[30])
        {
        }
        field(14; AddtlNtryInfFieldValue; Text[250])
        {
        }
        field(15; UstrdFieldValue1; Text[140])
        {
        }
        field(16; UstrdFieldValue2; Text[140])
        {
        }
        field(17; UstrdFieldValue3; Text[140])
        {
        }
        field(18; NumberOfStatements; Integer)
        {
        }
        field(19; HasStatementDateTag; Boolean)
        {
        }
        field(21; HasClosingBalanceTag; Boolean)
        {
        }
        field(22; CdFieldValue; Text[4])
        {
        }
        field(23; HasCdtDbtIndTagInBal; Boolean)
        {
        }
        field(24; HasCdtDbtIndTagInNtry; Boolean)
        {
        }
        field(25; Namespace; Text[100])
        {
        }
        field(26; SkipTxDtlsAmt; Boolean)
        {
        }
        field(27; RelatedPartyIBAN; Text[50])
        {
        }
        field(28; RelatedPartyBankAccount; Text[30])
        {
        }
        field(29; RelatedPartyName; Text[30])
        {
        }
        field(30; RelatedPartyAddress; Text[30])
        {
        }
        field(31; RelatedPartyCity; Text[30])
        {
        }
        field(32; EndToEndIdFieldValue; Text[30])
        {
        }
    }

    keys
    {
        key(Key1; Encoding)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

