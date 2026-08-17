#pragma warning disable AA0247
table 12409 "Bank Directory"
{
    Caption = 'Bank Directory';
    LookupPageID = "Bank Directory List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; BIC; Code[9])
        {
            Caption = 'BIC';
        }
        field(2; "Corr. Account No."; Code[20])
        {
            Caption = 'Corr. Account No.';
            MaskType = Concealed;
        }
        field(3; "Short Name"; Text[40])
        {
            Caption = 'Short Name';
        }
        field(4; "Full Name"; Text[140])
        {
            Caption = 'Full Name';
        }
        field(5; "Region Code"; Code[2])
        {
            Caption = 'Region Code';
        }
        field(6; "Post Code"; Code[10])
        {
            Caption = 'Post Code';
        }
        field(7; "Area Type"; Option)
        {
            Caption = 'Area Type';
            OptionCaption = ' ,Gorod,Poselok,Selo,Poselok gorodskogo tipa,Stanica,Aul,Rabochiy poselok';
            OptionMembers = " ",Gorod,Poselok,Selo,"Poselok gorodskogo tipa",Stanica,Aul,"Rabochiy poselok";
        }
        field(8; "Area Name"; Text[25])
        {
            Caption = 'Area Name';
        }
        field(9; Address; Text[40])
        {
            Caption = 'Address';
        }
        field(10; Telephone; Text[25])
        {
            Caption = 'Telephone';
        }
        field(11; OKPO; Code[8])
        {
            Caption = 'OKPO';
        }
        field(12; "Registration No."; Code[9])
        {
            Caption = 'Registration No.';
        }
        field(13; RKC; Code[9])
        {
            Caption = 'RKC';
        }
        field(14; Type; Option)
        {
            BlankZero = true;
            Caption = 'Type';
            OptionCaption = ' ,GRKC,RKC,Bank,Comm.Bank,Sber.Bank,Shar.Comm.Bank,Private Comm.Bank,Cooper.Bank,AgroPromBank,Bank Filial,Comm.Bamk Filial,SB Branch,Shar.Comm.Bank Filial,Private Bank Filial,Cooper.Bank Filial,AgroPromBank Filial,Field CB Branch,Central Depository,,Credit Organisation,Clearing Organisation,RC ORCB,Liq. in Progress,License Recalled,,,Liq. Commission';
            OptionMembers = " ",GRKC,RKC,Bank,"Comm.Bank","Sber.Bank","Shar.Comm.Bank","Private Comm.Bank","Cooper.Bank",AgroPromBank,"Bank Filial","Comm.Bamk Filial","SB Branch","Shar.Comm.Bank Filial","Private Bank Filial","Cooper.Bank Filial","AgroPromBank Filial","Field CB Branch","Central Depository",,"Credit Organisation","Clearing Organisation","RC ORCB","Liq. in Progress","License Recalled",,,"Liq. Commission";
        }
        field(15; "Last Modify Date"; Date)
        {
            Caption = 'Last Modify Date';
        }
        field(16; Status; Text[4])
        {
            Caption = 'Status';
        }
    }

    keys
    {
        key(Key1; BIC)
        {
            Clustered = true;
        }
        key(Key2; "Corr. Account No.")
        {
        }
    }

    fieldgroups
    {
    }
}

