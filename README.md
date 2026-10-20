# AgroFlow — Sistem za upravljanje poljoprivrednim gazdinstvom

**AgroFlow** je softverski sistem namenjen poljoprivrednim gazdinstvima za digitalizaciju radova na terenu, praćenje agrotehničkih faza obrade zemljišta, vođenje evidencije resursa i finansijsku analitiku. Vlasnici gazdinstava preko backoffice aplikacije upravljaju parcelama, mehanizacijom, magacinom i dodelom radnih naloga, dok radnici na terenu putem mobilne aplikacije prate zaduženja, beleže obavljene radove i unose potrošnju resursa i goriva bez potrebe za papirnom dokumentacijom.

## Tim

| Ime i prezime | Broj indeksa | Grupa | GitHub nalog |
| --- | --- | --- | --- |
| Milan Stojićević | 132/24 | 413 | Milan-Stojicevic |
| Luka Ušitkov | 72/24 | 413 | usitkov |

---

## Zahtevi za temu

### 1. Uloge
Sistem definiše sledeće uloge:
* **Radnik:** U mobilnoj aplikaciji vidi samo svoje dodeljene radne naloge na terenu, beleži obim obavljenog posla (hektare), utrošeno gorivo i upotrebljene resurse (seme, đubrivo, zaštitna sredstva).
* **Gazda / Menadžer:** U backoffice aplikaciji upravlja parcelama, mehanizacijom, radnicima i magacinom, kreira i dodeljuje radne naloge, odobrava ili odbija izveštaje radnika sa terena i ima uvid u kompletnu finansijsku analitiku i strukturu troškova po hektaru.

Radnik vidi samo svoje zadužene naloge, dok gazda ima potpun uvid i kontrolu nad celim sistemom.

### 2. Stanja
Glavni pojam sistema je **Radni nalog** koji se vezuje za parcelu i konkretnu agrotehničku meru. Radni nalog prolazi kroz stanja:

**Planiran** ➔ **U toku** ➔ **Čeka potvrdu** ➔ **Završen**

Uz bočna stanja:
* **Odbijen:** Gazda ne prihvata unete podatke sa terena (npr. pogrešno uneta količina goriva ili nepravilno obrađena površina) i vraća nalog na doradu.
* **Otkazan:** Gazda ili radnik otkazuju nalog pre ili tokom izvođenja (npr. zbog loših vremenskih prilika ili kvara mehanizacije).

### 3. Pravila
* **Sekvencijalnost agrotehničkih faza:** Server sprovodi pravilo obaveznog redosleda mera po parceli (oranje ➔ đubrenje ➔ setvospremanje ➔ sejanje ➔ prskanje ➔ vršaj). Radni nalog za narednu fazu ne može se započeti dok prethodna faza na toj parceli nije u stanju *završen*.
* **Ograničenje mehanizacije i radnika:** Isti radnik, traktor ili kombajn ne mogu imati dva radna naloga čiji se terminski intervali preklapaju.
* **Provera zaliha u magacinu:** Server blokira pokretanje radnog naloga za prskanje ili đubrenje ukoliko u magacinu nema dovoljno raspoloživih litara hemije ili kilograma đubriva.
* **Kapacitet parcele:** Ukupna suma unetih obrađenih hektara kroz radne naloge ne sme preći ukupnu definisanu površinu te parcele.

### 4. Rad bez mreže
Radnik na njivi bez signala može označiti početak i kraj rada, uneti obrađenu površinu, utrošak goriva i primenjena zaštitna sredstva. Svi podaci se beleže lokalno na uređaju i automatski šalju serveru po uspostavljanju internet veze. U slučaju sukoba (npr. ako je nalog u međuvremenu otkazan od strane gazde dok je radnik bio offline), sistem obaveštava radnika i čuva unete podatke kao nacrt za proveru. Pregled mapa parcela i istorije dodeljenih radnih naloga dostupan je i bez mreže u mobilnoj aplikaciji.

### 5. Posao za osoblje
Gazda u backoffice aplikaciji radi sa:
* **Pipeline / Kanban prikazom** napretka svih parcela kroz agrotehničke faze u sezoni.
* **Nedeljnim i dnevnim rasporedom** rada mehanizacije i radnika (Gantt dijagram zauzetosti traktora i priključnih mašina).
* **Interaktivnom mapom parcela** sa vizuelnim indikatorima stanja obrade i slojevima zauzetosti.
* **Dashboard-om analitike magacina i troškova** sa tabelarnim filtriranjem i grafikonom uloženo/ostvareno po hektaru.

### 6. Javni sadržaj
Bez prijave na sistem, posetiocima na javnom vebu dostupni su:
* Ponuda poljoprivrednih kultura koje gazdinstvo prodaje (kukuruz, pšenica, suncokret) sa cenama, raspoloživim količinama, rezultatima analize kvaliteta i lokacijom.
* Cenovnik uslužnih obrada (uslužno oranje, kombajniranje, prevoz).
* Poljoprivredni kalendar i javni saveti za obradu zemljišta.

---

## Delovi sistema

| Deo | Korisnici | Tehnologija | Platforme |
| --- | --- | --- | --- |
| **Mobilna aplikacija** | radnici na terenu | Flutter | Android, iOS |
| **Backoffice** | gazda, menadžeri | Flutter | Windows, veb |
| **Javni veb** | svi posetioci | Jaspr | pregledač |
| **Server** | ostali delovi sistema | Relic, PostgreSQL | Linux, Windows |
| **Domenski paket** | svi delovi sistema | Dart | sve |
