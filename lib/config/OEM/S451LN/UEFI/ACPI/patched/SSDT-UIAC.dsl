DefinitionBlock ("", "SSDT", 2, "hack", "_UIAC", 0)
{
    Device(UIAC)
    {
        Name(_HID, "UIA00000")

        Name(RMCF, Package()
        {
            // XHC (8086_9c31)
            "XHC", Package()
            {
                "port-count", Buffer() { 0x0B, 0x00, 0x00, 0x00 },
                "ports", Package()
                {
                      "HS01", Package()
                      {
                          "UsbConnector", 3,
                          "port", Buffer() { 0x01, 0x00, 0x00, 0x00 },
                      },
                      "HS02", Package()
                      {
                          "UsbConnector", 3,
                          "port", Buffer() { 0x02, 0x00, 0x00, 0x00 },
                      },
                      "HS03", Package()
                      {
                          "UsbConnector", 3,
                          "port", Buffer() { 0x03, 0x00, 0x00, 0x00 },
                      },
                      "HS04", Package()
                      {
                          "UsbConnector", 255,
                          "port", Buffer() { 0x04, 0x00, 0x00, 0x00 },
                      },
                      "HS05", Package()
                      {
                          "UsbConnector", 255,
                          "port", Buffer() { 0x05, 0x00, 0x00, 0x00 },
                      },
                      "HS08", Package()
                      {
                          "UsbConnector", 255,
                          "port", Buffer() { 0x08, 0x00, 0x00, 0x00 },
                      },
                      "SS01", Package()
                      {
                          "UsbConnector", 3,
                          "port", Buffer() { 0x0A, 0x00, 0x00, 0x00 },
                      },
                      "SS02", Package()
                      {
                          "UsbConnector", 3,
                          "port", Buffer() { 0x0B, 0x00, 0x00, 0x00 },
                      },
                },
            },
            // EH01 (8086_9c26)
            "EH01", Package()
            {
                "port-count", Buffer() { 0x01, 0x00, 0x00, 0x00 },
                "ports", Package()
                {
                      "PR11", Package()
                      {
                          "UsbConnector", 255,
                          "port", Buffer() { 0x01, 0x00, 0x00, 0x00 },
                      },
                },
            },
            // EH01 (8086_9c26)
            "HUB1", Package()
            {
                "port-count", Buffer() { 0x03, 0x00, 0x00, 0x00 },
                "ports", Package()
                {
                      "HP13", Package()
                      {
                          "portType", 3,
                          "port", Buffer() { 0x03, 0x00, 0x00, 0x00 },
                      },
                },
            },
        })
    }
}
