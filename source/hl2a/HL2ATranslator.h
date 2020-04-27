#ifndef UDA_HL2A_HL2ATRANSLATOR_H
#define UDA_HL2A_HL2ATRANSLATOR_H
#include "BaseTypes.h"
#include "ITranslator.h"
#include "IDataManager.h"
#include <stdio.h>
#include <list>
#include "HL2AConverter.h"

using namespace std;
#define TESTDATA "/home/fanze/share/";
namespace HL2A
{
	
	struct DATA_INF
	{
		char filetype[10];         //0   �ļ����ͣ��̶�Ϊ��swip_das"
		short int chnl_id;         //10  ͨ�� ID
		char chnl[12];             //12  ͨ���ź�����
		int addr;                  //24  ����ָ��
		float freq;                //28  ������
		int len;                   //32  ���ݲɼ�����
		int post;                  //36  ������ɼ�����
		unsigned short int maxDat; //40  ������ʱ�� A/D ת��ֵ
		float lowRang;             //42  ��������
		float highRang;            //46  ��������
		float factor;              //50  ϵ������
		float offset;              //54  �ź�ƫ����
		char unit[8];              //58  ��������λ
		float dly;                 //66  ������ʱ(ms)
		short int attribDt;        //70  �������ԣ�A/D����1�� ��������2��ʵ������3
		short int datWth;          //72  �����ֿ��
		short int sparI1;          //74  ����2�ֽ����� 1
		short int sparI2;          //76  ����2�ֽ����� 2
		short int sparI3;          //78  ����2�ֽ����� 3
		float sparF1;              //80  ����4�ֽڸ��� 1
		float sparF2;              //84  ����4�ֽڸ��� 2
		char sparC1[8];            //88  �����ַ��� 1
		char sparC2[16];           //96  �����ַ��� 2
		char sparC3[10];           //112 �����ַ��� 3
	};
	enum DataType
	{
		Int16 = 1,
		Float = 2,
		Int32 = 3,
		Other = 4
	};

	struct HL2A_DATA
	{
		short int chnl_id;         //10  ͨ�� ID
		char chnl[12];             //12  ͨ���ź�����
		DataType dtType;
		int dtCnt;
		int yDataLength;
		void * xData;
		void * yData;
	};
	
	class HL2ATranslator : public ITranslator
	{
	public:
		virtual HL2AResult DoTranslate(char * keyParam, char * reserved, IDataManager dataManager);
		
		virtual HL2AResult DoTranslateWithOutputParam(char * keyParam, unsigned char * reserved, IDataManager dataManager);

		virtual HL2AResult DoRead(char * keyParam, char * reserved, IDataManager dataManager);

		explicit HL2ATranslator()
		{

		}
		
	private:
		
		const char * _pDefualtDir = "/home/fanze/share/";
		const char * DATADIR = "HL2A_DATADIR";

		char * ToXml(list<HL2A_DATA> * listData, int * dataLength);
		char _directory[300];
		HL2A_DATA * ProcessChannelData(DATA_INF* inf, FILE * fDat);
		void OpenHL2AFile(char * keyParam, FILE ** fInf, FILE ** fDat);

		bool Translate(char * keyParam, list<HL2A_DATA> * listData, IDataManager dataManager);

		void ToInf(DATA_INF * inf, char * buffer);
		Converter _converter;


		
	};
}


#endif




