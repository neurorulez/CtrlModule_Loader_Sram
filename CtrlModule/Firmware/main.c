#include "host.h"

#include "minfat.h"
#include "spi.h"
#include <string.h>

fileTYPE file;
void Delay()
{
	int c=16384; // delay some cycles
	while(c)
	{
		c--;
	}
}

void SuperDelay()
{	int i=1;
	for (i=1;i<=576;i++)
	{
		Delay();
	}
}

static int LoadROM(const char *filename)
{
	int result=0;
	int opened;
	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_RESET |  HOST_CONTROL_DIVERT_SDCARD; // Hacer reset y tomar el control de la SD

	if((opened=FileOpen(&file,filename)))
	{
		int filesize=file.size;
		unsigned int c=0;
		int bits;

		HW_HOST(REG_HOST_ROMSIZE) = file.size;

		bits=0;
		c=filesize-1;
		while(c)
		{
			++bits;
			c>>=1;
		}
		bits-=9;

		result=1;
		while(filesize>0)
		{
			if(FileRead(&file,sector_buffer))
			{
				int i;
				int *p=(int *)&sector_buffer;
				for(i=0;i<512;i+=4)
				{
					unsigned int t=*p++;
					unsigned char t1=t;
					unsigned char t2=t>>8;
					unsigned char t3=t>>16;
					unsigned char t4=t>>24;
					HW_HOST(REG_HOST_BOOTDATA)=t4;
					HW_HOST(REG_HOST_BOOTDATA)=t3;
					HW_HOST(REG_HOST_BOOTDATA)=t2;
					HW_HOST(REG_HOST_BOOTDATA)=t1;
				}
			}
			else
			{
				result=0;
				filesize=512;
			}
			FileNextSector(&file);
			filesize-=512;
			++c;
		}
	}
//	SuperDelay();
	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_DIVERT_SDCARD; // Suelta el reset y mantenemos el control de la SD
	return(result);
}


int main(int argc,char **argv)
{
	int i;
	int dipsw=0;

	//PS2Init();
	EnableInterrupts();

	if(!FindDrive())
		return(0);


	LoadROM("SPECTRUMROM");

	
	return(0);
}
