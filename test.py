from os import name
from flask import Flask, redirect, url_for, render_template, request, session, flash
from datetime import timedelta
import mysql.connector
import numpy

app = Flask(__name__)
app.secret_key = "test"
db = mysql.connector.connect(
    host="localhost",
    user="root",
    passwd="root",
    database="sustav_za_vodjenje_drzavne_mature"
)


app.permanent_session_lifetime = timedelta(days=5)

@app.route("/")
def home():
        return render_template("index.html", content="Testing")

@app.route("/login", methods=["POST", "GET"])
def login():
    if request.method == "POST":
        session.permanent = True
        user = request.form["nm"]
        session["userEmail"] = request.form["nm"]
        if(user == 'admin@gmail.com'):
            session["user"] = user
            flash("Admin login")
            return redirect(url_for("prikazprigovora"))
        else:
            user = request.form["nm"]
            cur = db.cursor()
            cur2 = db.cursor()
            cur2.execute("SELECT email FROM ucenik")
            svakiMailUcenika = cur2.fetchall()
            for i in svakiMailUcenika:
                if user == ''.join(i[0]):
                    cur.execute("SELECT id FROM ucenik WHERE email ='"+user+"'")
                    rezultat2 = cur.fetchall()
                    session["user"] = str(sum(rezultat2[0]))
                    flash("Login succesful! ")
                    return redirect(url_for("user"))
                    
            cur2.execute("SELECT email FROM voditelj")
            svakiMailVoditelja = cur2.fetchall()
            for i in svakiMailVoditelja:
                if user == ''.join(i[0]):
                    cur.execute("SELECT id FROM voditelj WHERE email ='"+user+"'")
                    rezultat2 = cur.fetchall()
                    session["user"] = str(sum(rezultat2[0]))
                    flash("Login succesful! ")
                    return redirect(url_for("voditelj"))
                    
            cur2.execute("SELECT email FROM ocjenjivac")
            svakiMailOcjenjivaca = cur2.fetchall()
            for i in svakiMailOcjenjivaca:
                if user == ''.join(i[0]):
                    cur.execute("SELECT id FROM ocjenjivac WHERE email ='"+user+"'")
                    rezultat2 = cur.fetchall()
                    session["user"] = str(sum(rezultat2[0]))
                    flash("Login succesful! ")
                    return redirect(url_for("ocjenjivac"))
                else:
                    flash('Nepostojeci mail')
                    return render_template("login.html")
    else:
        if "user" in session:
            flash("Already logged in!")
            return redirect(url_for("login",))
        return render_template("login.html")


@app.route("/signup", methods=["POST", "GET"])
def signup():
    cur = db.cursor()
    cur2 = db.cursor()
    cur3 = db.cursor()
    cur4 = db.cursor()
    cur5 = db.cursor()
    cur2.execute("SELECT naziv FROM grad")
    predmeti = cur2.fetchall()
    cur3.execute("SELECT naziv FROM skola")
    skole = cur3.fetchall()
    if request.method == "POST":
        ime = request.form["ime"]
        prezime = request.form["prezime"]
        oib = request.form["oib"]
        email = request.form["email"]
        spol = request.form["spol"]
        dan = request.form["dan"]
        mjesec = request.form["mjesec"]
        godina = request.form["godina"]
        grad = request.form["grad"]
        skola = request.form["skola"]
        cur4.execute("SELECT id FROM grad WHERE naziv = '"+grad+"'")
        id_grad = cur4.fetchall()
        cur5.execute("SELECT id FROM skola WHERE naziv = '"+skola+"'")
        id_skola = cur5.fetchall()
        cur.execute("INSERT INTO ucenik (ime, prezime, oib, datum_rodjenja, spol, id_grad, id_skola, email) VALUES (%s, %s, %s, STR_TO_DATE('"+dan+"."+mjesec+"."+godina+".', '%d.%m.%Y.'), %s, %s, %s, %s)", (ime,prezime,oib,spol,str(sum(id_grad[0])),str(sum(id_skola[0])),email))
        flash("Račun izrađen")
        return render_template("signup.html", predmeti=predmeti, skole=skole)
    else:
        if "user" in session:
            flash("Already logged in!")
            return redirect(url_for("login",))
        return render_template("signup.html", predmeti=predmeti, skole=skole)

@app.route("/user", methods=["POST", "GET"])
def user():
    cur = db.cursor()
    cur2 = db.cursor()
    cur3 = db.cursor()
    cur4 = db.cursor()
    rezultat = cur.execute("SELECT naziv FROM predmet")
    predmeti = cur.fetchall()
    email = None
    if "user" in session:
        user = session["user"]

        if request.method == "POST":
            predmet = request.form['pr']
            razina = request.form['raz']
            if(razina == 'izborni'):
                razina = 'jedna_razina'
            rok = request.form['ro']
            rezultati2 = cur3.execute("SELECT matura.id FROM matura INNER JOIN predmet ON predmet.id = id_predmet INNER JOIN razina ON razina.id = id_razina INNER JOIN termin_ispita ON termin_ispita.id = id_termin_ispita WHERE predmet.naziv ='" + predmet + "' AND razina.naziv ='"+razina+ "' AND termin_ispita.vrsta_roka ='"+rok+"'")
            id_matura = cur3.fetchall()
            rezultati3 = cur4.execute("SELECT predmet.naziv FROM ocjena_na_maturi INNER JOIN matura ON matura.id = id_matura INNER JOIN predmet ON predmet.id = id_predmet WHERE id_ucenik = '"+session["user"]+"' AND predmet.naziv = '"+predmet+"'")
            matura_vec_postoji = cur4.fetchall()
            if(matura_vec_postoji):
                flash("Predmet je vec prijavljen")
            else:
                cur2.execute("INSERT INTO ocjena_na_maturi (id_matura, id_ucenik, id_ocjenjivac) VALUES (%s, %s, %s)", (sum(id_matura[0]), session["user"], 1))
                flash("Predmet je prijavljen")
        else:
            if "email" in session:
                email = session["email"]
        return render_template("user.html", email=email, predmeti=predmeti)
    else:
        flash("You are not logged in!")
        return redirect(url_for("login"))

@app.route("/ocjenjivac", methods=["POST", "GET"])
def ocjenjivac():
    cur = db.cursor()
    cur2 = db.cursor()
    cur.execute("SELECT ocjena_na_maturi.id, predmet.naziv, razina.naziv, ucenik.ime, ucenik.prezime, ucenik.oib, ocjena FROM ocjena_na_maturi INNER JOIN matura ON matura.id = id_matura INNER JOIN razina ON id_razina = razina.id INNER JOIN predmet ON id_predmet = predmet.id INNER JOIN ucenik ON ucenik.id = id_ucenik WHERE id_ocjenjivac ="+session["user"])
    predmet = cur.fetchall()
    email = None
    if "user" in session:
        if request.method == "POST":
            id = request.form["id"]
            bod = request.form["bod"]
            cur2.execute("UPDATE ocjena_na_maturi SET broj_bodova = %s WHERE id = %s", (bod, id))
            flash("Bodovi upisani ")
        return render_template("ocjenjivac.html", email=email, predmet=predmet)
    else:
        flash("You are not logged in!")
        return redirect(url_for("login"))

@app.route("/ocjenjivacPrigovori", methods=["POST", "GET"])
def ocjenjivacPrigovori():
    cur2 = db.cursor()
    cur3 = db.cursor()
    cur4 = db.cursor()
    cur5 = db.cursor()
    cur2.execute("SELECT ocjena_na_maturi.id, tema_prigovora, opis_prigovora, ime, prezime FROM ocjena_na_maturi INNER JOIN ucenik ON ucenik.id = id_ucenik INNER JOIN prigovor ON id_ocjena_na_maturi = ocjena_na_maturi.id WHERE id_ocjenjivac="+session["user"])
    prigovor = cur2.fetchall()
    cur4.execute("SELECT ime, prezime FROM prigovor INNER JOIN ocjena_na_maturi ON id_ocjena_na_maturi = ocjena_na_maturi.id INNER JOIN ucenik ON id_ucenik = ucenik.id")
    id_ocjena_na_maturi = cur4.fetchall()
    cur5.execute("SELECT predmet.naziv FROM prigovor INNER JOIN ocjena_na_maturi ON id_ocjena_na_maturi = ocjena_na_maturi.id INNER JOIN matura ON matura.id = id_matura INNER JOIN predmet ON predmet.id = id_predmet")
    predmet = cur5.fetchall()
    email = None
    if "user" in session:
        return render_template("ocjenjivacPrigovori.html", email=email, prigovor=prigovor)
    else:
        flash("You are not logged in!")
        return redirect(url_for("login"))  

@app.route("/ocjenjivacEdukacija", methods=["POST", "GET"])
def ocjenjivacEdukacija():
    cur5 = db.cursor()
    cur5.execute("SELECT predmet.naziv, termin_edukacije FROM edukacija_termin INNER JOIN edukacija ON id_edukacija_termin = edukacija_termin.id INNER JOIN predmet ON predmet.id = id_predmet WHERE id_ocjenjivac ="+session['user'])
    edukacija = cur5.fetchall()
    email = None
    if "user" in session:
        return render_template("ocjenjivacEdukacija.html", email=email, edukacija=edukacija)
    else:
        flash("You are not logged in!")
        return redirect(url_for("login"))  

@app.route("/voditelj", methods=["POST", "GET"])
def voditelj():
    cur = db.cursor()
    cur.execute("SELECT predmet.naziv, razina.naziv, skola.naziv, grad.naziv, datum_ispita, pocetak, duljina_trajanja FROM voditelj INNER JOIN matura ON matura.id = id_matura INNER JOIN predmet ON predmet.id = id_predmet INNER JOIN skola ON skola.id = id_skola INNER JOIN grad ON grad.id = id_grad INNER JOIN razina ON id_razina = razina.id INNER JOIN termin_ispita ON termin_ispita.id = id_termin_ispita INNER JOIN vrijeme ON vrijeme.id = id_vrijeme WHERE voditelj.id ="+session["user"])
    matura = cur.fetchall()
    email = None
    if "user" in session:
        return render_template("voditelj.html", email=email, matura=matura)
    else:
        flash("You are not logged in!")
        return redirect(url_for("login"))

@app.route("/admin", methods=["POST", "GET"])
def admin():
    cur = db.cursor()
    cur2 = db.cursor()
    cur3 = db.cursor()
    cur4 = db.cursor()
    cur.execute("SELECT naziv FROM predmet")
    cur.fetchall()
    if "user" in session:
        if request.method == "POST":
            predmet = request.form['pr']
            razina = request.form['raz']
            if(razina == 'izborni'):
                razina = 'jedna_razina'
            rok = request.form['ro']
            cur3.execute("SELECT matura.id FROM matura INNER JOIN predmet ON predmet.id = id_predmet INNER JOIN razina ON razina.id = id_razina INNER JOIN termin_ispita ON termin_ispita.id = id_termin_ispita WHERE predmet.naziv ='" + predmet + "' AND razina.naziv ='"+razina+ "' AND termin_ispita.vrsta_roka ='"+rok+"'")
            id_matura = cur3.fetchall()
            cur4.execute("SELECT predmet.naziv FROM ocjena_na_maturi INNER JOIN matura ON matura.id = id_matura INNER JOIN predmet ON predmet.id = id_predmet WHERE id_ucenik = '"+session["user"]+"' AND predmet.naziv = '"+predmet+"'")
            matura_vec_postoji = cur4.fetchall()
            if(matura_vec_postoji):
                flash("Predmet je vec prijavljen")
            else:
                cur2.execute("INSERT INTO ocjena_na_maturi (id_matura, id_ucenik) VALUES (%s, %s)", (sum(id_matura[0]), session["user"]))
                flash("Predmet je prijavljen")
        else:
            if "email" in session:
                email = session["email"]
        return render_template("admin.html")
    else:
        flash("You are not logged in!")
        return redirect(url_for("login"))      


@app.route("/prikazprigovora", methods=["POST", "GET"])
def prikazprigovora():
    cur2 = db.cursor()
    cur3 = db.cursor()
    cur4 = db.cursor()
    cur5 = db.cursor()
    cur2.execute("SELECT tema_prigovora FROM prigovor")
    tema = cur2.fetchall()
    cur3.execute("SELECT opis_prigovora FROM prigovor")
    prigovor = cur3.fetchall()
    cur4.execute("SELECT ime, prezime FROM prigovor INNER JOIN ocjena_na_maturi ON id_ocjena_na_maturi = ocjena_na_maturi.id INNER JOIN ucenik ON id_ucenik = ucenik.id")
    id_ocjena_na_maturi = cur4.fetchall()
    cur5.execute("SELECT predmet.naziv FROM prigovor INNER JOIN ocjena_na_maturi ON id_ocjena_na_maturi = ocjena_na_maturi.id INNER JOIN matura ON matura.id = id_matura INNER JOIN predmet ON predmet.id = id_predmet")
    predmet = cur5.fetchall()
    email = None
    if "user" in session:
        return render_template("prikazprigovora.html", email=email, tema=tema, prigovor=prigovor, id_ocjena_na_maturi=id_ocjena_na_maturi, predmet=predmet)
    else:
        flash("You are not logged in!")
        return redirect(url_for("login"))          

@app.route("/prijave", methods=["POST", "GET"])
def prijave():
    cur = db.cursor()
    cur2 = db.cursor()
    cur3 = db.cursor()
    cur4 = db.cursor()
    cur5 = db.cursor()
    cur6 = db.cursor()
    cur.execute("SELECT predmet.naziv FROM ocjena_na_maturi INNER JOIN matura ON matura.id = id_matura INNER JOIN predmet ON predmet.id = id_predmet WHERE id_ucenik = %s"%session["user"])
    prijave = cur.fetchall()
    cur2.execute("SELECT datum_ispita FROM ocjena_na_maturi INNER JOIN matura ON matura.id = id_matura INNER JOIN termin_ispita ON termin_ispita.id = id_termin_ispita WHERE id_ucenik = %s"%session["user"])
    datumi = cur2.fetchall()
    cur3.execute("SELECT duljina_trajanja FROM ocjena_na_maturi INNER JOIN matura ON matura.id = id_matura INNER JOIN vrijeme ON vrijeme.id = id_vrijeme WHERE id_ucenik = %s"%session["user"])
    trajanja = cur3.fetchall()
    cur4.execute("SELECT pocetak FROM ocjena_na_maturi INNER JOIN matura ON matura.id = id_matura INNER JOIN vrijeme ON vrijeme.id = id_vrijeme WHERE id_ucenik = %s"%session["user"])
    pocetci = cur4.fetchall()
    cur5.execute("SELECT ocjena FROM ocjena_na_maturi WHERE id_ucenik = %s"%session["user"])
    ocjene = cur5.fetchall()
    cur6.execute("SELECT razina.naziv FROM ocjena_na_maturi INNER JOIN matura ON matura.id = id_matura INNER JOIN razina ON razina.id = id_razina WHERE id_ucenik = %s"%session["user"])
    razine = cur6.fetchall()
    email = None
    if "user" in session:
        user = session["user"]

        if request.method == "POST":
            email = request.form["email"]
            session["email"] = email
            flash("Email was saved!")
        else:
            if "email" in session:
                email = session["email"]
        return render_template("prijave.html", email=email, prijave=prijave, datumi=datumi, trajanja=trajanja, pocetci=pocetci, ocjene=ocjene, razine=razine)
    else:
        flash("You are not logged in!")
        return redirect(url_for("login"))

@app.route("/mojipodaci", methods=["POST", "GET"])
def mojipodaci():
    cur = db.cursor()
    cur.execute("SELECT ime FROM ucenik WHERE id = %s"%session["user"])
    ime = cur.fetchall()
    cur2 = db.cursor()
    cur2.execute("SELECT prezime FROM ucenik WHERE id = %s"%session["user"])
    prezime = cur2.fetchall()
    cur3 = db.cursor()
    cur3.execute("SELECT oib FROM ucenik WHERE id = %s"%session["user"])
    oib = cur3.fetchall()
    cur4 = db.cursor()
    cur4.execute("SELECT datum_rodjenja FROM ucenik WHERE id = %s"%session["user"])
    datum_rodjenja = cur4.fetchall()
    cur5 = db.cursor()
    cur5.execute("SELECT spol FROM ucenik WHERE id = %s"%session["user"])
    spol = cur5.fetchall()
    cur6 = db.cursor()
    cur6.execute("SELECT grad.naziv FROM ucenik INNER JOIN grad ON grad.id = id_grad WHERE ucenik.id = %s"%session["user"])
    grad = cur6.fetchall()
    cur7 = db.cursor()
    cur7.execute("SELECT skola.naziv FROM ucenik INNER JOIN skola ON skola.id = id_skola WHERE ucenik.id = %s"%session["user"])
    skola = cur7.fetchall()
    email = None
    if "user" in session:
        user = session["user"]

        if request.method == "POST":
            email = request.form["email"]
            session["email"] = email
            flash("Email was saved!")
        else:
            if "email" in session:
                email = session["email"]
        return render_template("mojipodaci.html", email=email, ime=ime, prezime=prezime, oib=oib, datum_rodjenja=datum_rodjenja, spol=spol, grad=grad, skola=skola)
    else:
        flash("You are not logged in!")
        return redirect(url_for("login"))

@app.route("/drzavnemature", methods=["POST", "GET"])
def drzavnemature():
    cur = db.cursor()
    cur.execute("SELECT predmet.naziv, datum_ispita, pocetak, razina.naziv, opis FROM matura INNER JOIN predmet ON id_predmet = predmet.id INNER JOIN termin_ispita ON termin_ispita.id = id_termin_ispita INNER JOIN razina ON razina.id = id_razina INNER JOIN vrijeme ON vrijeme.id = id_vrijeme")
    predmet = cur.fetchall()
    cur2 = db.cursor()
    cur2.execute("SELECT datum_ispita FROM matura INNER JOIN termin_ispita ON termin_ispita.id = id_termin_ispita")
    datum_ispita = cur2.fetchall()
    cur3 = db.cursor()
    cur3.execute("SELECT pocetak FROM matura INNER JOIN vrijeme ON id_vrijeme = vrijeme.id")
    pocetak = cur3.fetchall()
    cur4 = db.cursor()
    cur4.execute("SELECT naziv FROM matura INNER JOIN razina ON razina.id = id_razina")
    razina = cur4.fetchall()
    cur5 = db.cursor()
    cur5.execute("SELECT opis FROM matura")
    opis = cur5.fetchall()
    email = None
    return render_template("drzavnemature.html", email=email, predmet=predmet, datum_ispita=datum_ispita, pocetak=pocetak, razina=razina, opis=opis)

@app.route("/prikazedukacija", methods=["POST", "GET"])
def prikazedukacija():
    cur = db.cursor()
    cur.execute("SELECT predmet.naziv FROM edukacija_termin INNER JOIN predmet ON id_predmet = predmet.id")
    predmet = cur.fetchall()
    cur2 = db.cursor()
    cur2.execute("SELECT termin_edukacije FROM edukacija_termin")
    datum_edukacije = cur2.fetchall()
    email = None
    return render_template("prikazedukacija.html", email=email, predmet=predmet, datum_edukacije=datum_edukacije)
  

@app.route("/prigovor", methods=["POST", "GET"])
def prigovor():
    cur = db.cursor()
    cur2 = db.cursor()
    # cur2.execute("SELECT ocjena_na_maturi.id FROM ocjena_na_maturi INNER JOIN matura ON matura.id = id_matura INNER JOIN predmet ON predmet.id = id_predmet WHERE predmet.naziv = 'Hrvatski' AND id_ucenik = 1") 
    # idOcjenaNaMaturi = cur2.fetchall()
    # flash(idOcjenaNaMaturi)
    cur3 = db.cursor()
    cur4 = db.cursor()
    if "user" in session:
        user = session["user"]
        cur3.execute("SELECT naziv FROM predmet")
        predmeti = cur3.fetchall()

        if request.method == "POST":
            temaPrigovora = request.form['txt']
            prigovor = request.form['txt2']
            predmet = request.form['pr']
            cur2.execute("SELECT ocjena_na_maturi.id FROM ocjena_na_maturi INNER JOIN matura ON matura.id = id_matura INNER JOIN predmet ON predmet.id = id_predmet WHERE predmet.naziv ='"+predmet+"' AND id_ucenik ="+session["user"]) 
            idOcjenaNaMaturi = cur2.fetchall()
            cur.execute("INSERT INTO prigovor VALUES (NULL,'"+temaPrigovora+"','"+prigovor+"','"+str(sum(idOcjenaNaMaturi[0]))+"')")
            flash("Prigovor poslan")
        else:
            if "email" in session:
                email = session["email"]
        return render_template("prigovor.html", predmeti=predmeti)
    else:
        flash("You are not logged in!")
        return redirect(url_for("login"))

@app.route("/logout")
def logout():
    if "user" in session:
        user = session["user"]
        flash(f"You have been logged out", "info")
    session.pop("user", None)
    session.pop("userEmail", None)
    return redirect(url_for("login"))

if __name__ == "__main__":
    app.run(debug=True)