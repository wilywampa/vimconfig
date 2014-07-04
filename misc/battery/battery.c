#include <stdio.h>
#include <Windows.h>

int main()
{
    SYSTEM_POWER_STATUS pwr;
    GetSystemPowerStatus(&pwr);

    if (pwr.BatteryFlag & 8)
        printf("⚡");
    else if (pwr.BatteryFlag & 1)
        printf("✓");

    printf("%d%%", pwr.BatteryLifePercent);

    return 0;
}
