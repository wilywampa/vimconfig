#include <stdio.h>
#include <Windows.h>

int main(int argc, char const* argv[])
{
    SYSTEM_POWER_STATUS pwr;
    GetSystemPowerStatus(&pwr);

    if (pwr.BatteryFlag & 8)
        printf("⚡");

    printf("%d%%", pwr.BatteryLifePercent);

    return 0;
}
