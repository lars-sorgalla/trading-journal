from google.oauth2 import service_account
from googleapiclient.discovery import build, Resource
from typing import Optional, Any

SERVICE_ACCOUNT_FILE = "../config/gsheets_api_keys.json"
SCOPES = ["https://www.googleapis.com/auth/spreadsheets.readonly"]
SPREADSHEET_ID = "1M5SY1fZENzqp8h4JwmJVzWrXsSp0bk4V1UoZAyuLn04"


def _get_credentials() -> Any:
    """Retrieve credentials for Google service account by providing SERVICE_ACCOUNT_FILE

    :return: Credentials instance from service account json file - Any
    """
    creds = service_account.Credentials.from_service_account_file(filename=SERVICE_ACCOUNT_FILE, scopes=SCOPES)
    return creds


def _get_resource(creds: Any) -> Resource:
    """Create an entry point into google sheets API by constructing a :class:`Resource`. This will subsequently be
    used to get the sheet data

    :param creds: Any
    :return: Resource
    """
    service: Optional[Any] = build("sheets", "v4", credentials=_get_credentials())
    sheet: Resource = service.spreadsheets()
    return sheet


def get_sheet_data() -> dict:
    """Call Google sheets API and extract data

    :return: dict
    """
    creds = _get_credentials()
    sheet = _get_resource(creds)
    sheet_data: dict = sheet.values().get(spreadsheetId=SPREADSHEET_ID, range="Trading Journal!B2:AJ10000",
                                          valueRenderOption="UNFORMATTED_VALUE").execute()
    return sheet_data


# for testing purposes
if __name__ == '__main__':
    creds: Any = _get_credentials()
    resource: Resource = _get_resource(creds)
    print(type(resource))
    print(get_sheet_data()["values"])
    print(f'{type(get_sheet_data()["values"])=}')
