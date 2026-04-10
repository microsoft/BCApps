report 134601 "Test Report - Default=RDLC"
{
    DefaultRenderingLayout = "./Test Report - Default=RDLC.rdlc";

    dataset
    {
        dataitem(Customer; Customer)
        {
            column(No; "No.")
            {
                IncludeCaption = true;
            }
            column(Name; Name)
            {
                IncludeCaption = true;
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    rendering
    {
        layout("./Test Report - Default=RDLC.rdlc")
        {
            Type = RDLC;
            LayoutFile = './Test Report - Default=RDLC.rdlc';
        }
        layout("./Test Report - Default=RDLC.docx")
        {
            Type = Word;
            LayoutFile = './Test Report - Default=RDLC.docx';
        }
    }

    labels
    {
    }
}

