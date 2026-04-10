report 134600 "Test Report - Default=Word"
{
    DefaultRenderingLayout = "./Test Report - Default=Word.docx";

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
        layout("./Test Report - Default=Word.rdlc")
        {
            Type = RDLC;
            LayoutFile = './Test Report - Default=Word.rdlc';
        }
        layout("./Test Report - Default=Word.docx")
        {
            Type = Word;
            LayoutFile = './Test Report - Default=Word.docx';
        }
    }

    labels
    {
    }
}

