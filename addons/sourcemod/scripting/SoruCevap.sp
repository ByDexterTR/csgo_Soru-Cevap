#include <sourcemod>
#include <store>

#pragma semicolon 1
#pragma newdecls required

static char Dosya[PLATFORM_MAX_PATH];

public Plugin myinfo = 
{
	name = "Soru Cevap", 
	author = "ByDexter", 
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

Handle Zamanlayici = null;
ConVar Sure = null, Yanit = null, Gosterge = null;
bool OyunAktif = false;
char Cevap[256], Odul[20];

public void OnPluginStart()
{
	Gosterge = CreateConVar("sm_sorucevap_cevap", "1", "Soruyu bilemezlerse cevabı yazılsın mı? [ 0 = Hayır | 1 = Evet ]", 0, true, 0.0, true, 1.0);
	Sure = CreateConVar("sm_sorucevap_timer", "300.0", "Kaç saniye arayla çıksın sorular", 0, true, 5.0, true, 3600.0);
	Yanit = CreateConVar("sm_sorucevap_yanit", "10.0", "Kaç saniye sonra soru zaman aşımına uğraşsın.", 0, true, 5.0, true, 30.0);
	Sure.AddChangeHook(SureHook);
	BuildPath(Path_SM, Dosya, sizeof(Dosya), "ByDexter/SoruCevap.txt");
	AutoExecConfig(true, "SoruCevap", "ByDexter");
}

public void OnMapStart()
{
	OyunAktif = false;
	Zamanlayici = CreateTimer(Sure.FloatValue, SoruCikar, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void SureHook(ConVar convar, const char[] oldValue, const char[] newValue)
{
	delete Zamanlayici;
	Zamanlayici = CreateTimer(Sure.FloatValue, SoruCikar, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action SoruCikar(Handle timer)
{
	KeyValues kv = new KeyValues("ByDexter");
	kv.ImportFromFile(Dosya);
	char SoruSayi[8];
	kv.GetString("toplamsoru", SoruSayi, 8);
	char Keyi[20];
	Format(Keyi, 20, "%d", GetRandomInt(1, StringToInt(SoruSayi)));
	if (kv.JumpToKey(Keyi, false))
	{
		char Soru[512];
		kv.GetString("soru", Soru, 512);
		kv.GetString("cevap", Cevap, 256);
		kv.GetString("ödül", Odul, 20);
		PrintToChatAll("------------------------------------------------");
		PrintToChatAll("[SM] \x0EGaglı oyuncularda yazabilir!");
		PrintToChatAll("[SM] \x04%s", Soru);
		OyunAktif = true;
	}
	kv.Rewind();
	kv.ExportToFile(Dosya);
	delete kv;
	Zamanlayici = null;
	CreateTimer(Yanit.FloatValue, ZamanAsimi, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Stop;
}

public Action ZamanAsimi(Handle timer)
{
	if (!OyunAktif)
	{
		return Plugin_Stop;
	}
	PrintToChatAll("[SM] \x01Kimse bilemediği için soru \x07zaman aşımına uğradı!");
	OyunAktif = false;
	Zamanlayici = CreateTimer(Sure.FloatValue, SoruCikar, _, TIMER_FLAG_NO_MAPCHANGE);
	if (Gosterge.BoolValue)
		PrintToChatAll("[SM] Cevap: \x04%s", Cevap);
	
	return Plugin_Stop;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (OyunAktif && strcmp(sArgs, Cevap, false) == 0)
	{
		OyunAktif = false;
		PrintToChatAll("[SM] \x10%N \x01soruyu doğru bildi ve \x04%d Kredi \x01kazandı.", client, StringToInt(Odul));
		Zamanlayici = CreateTimer(Sure.FloatValue, SoruCikar, _, TIMER_FLAG_NO_MAPCHANGE);
		Store_SetClientCredits(client, Store_GetClientCredits(client) + StringToInt(Odul));
	}
} 