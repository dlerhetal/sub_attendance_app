import gspread

gs = gspread.service_account(filename='assets/credentials.json')
spreadsheet_url = 'https://docs.google.com/spreadsheets/d/15H1fsYaC1sN_dd2idWlumand3k206IhiFmQOIXPPeMw/edit?usp=sharing'

try:
    sh = gs.open_by_url(spreadsheet_url)
    print("Worksheets found:")
    for worksheet in sh.worksheets():
        print(f"- {worksheet.title}")

    worksheet = sh.worksheet('Lists')
    subcontractor_names = worksheet.col_values(1)[1:1000] # A2:A1000, col_values is 1-indexed, slice for rows
    print("\nSubcontractor Names:")
    for name in subcontractor_names:
        if name:
            print(name)
except gspread.exceptions.SpreadsheetNotFound:
    print(f"Error: Spreadsheet not found at {spreadsheet_url}")
except gspread.exceptions.WorksheetNotFound:
    print("Error: 'lists' worksheet not found. Please check the exact worksheet name.")
except Exception as e:
    print(f"An unexpected error occurred: {e}")