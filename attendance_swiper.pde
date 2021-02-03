import java.util.*;
import javax.mail.*;
import javax.mail.internet.*;
import javax.activation.*;
import controlP5.*;
import java.io.*;

boolean rpi = false;
boolean acceptSwipeFlag = false;
String defaultEvent = "My Event";
String defaultEmail = "joel@matthysmusic.com";
String text = "";
String digits = "";
String dateStamp;
boolean code16 = false;
PrintWriter output, finalFile;
String filename;
final int debounce = 1000; // time in ms to retrigger
int pressedTime;
final int gpioPin = 10;
boolean export = false;
final int showIDtime = 3000; // ms
int swipes = 0;
int swipeTime;
File temp;
String desktopPath;
PFont font;

Properties props;
Session session;

ControlP5 cp5;

void setup()
{
  size(460, 300);
  smooth();
  background(0);
  try {
    temp = File.createTempFile("attendance_p5_", ".csv");
    desktopPath =System.getProperty("user.home") + "/Desktop/";
  }
  catch (Exception e)
  {
    e.printStackTrace();
    temp = new File("tempfile.csv");
  }
  dateStamp = nf(month(), 2)+"/"+nf(day(), 2)+"/"+nf(year(), 4);
  props = System.getProperties();
  props.put("mail.transport.protocol", "smtp");
  props.put("mail.smtp.host", "mail.gandi.net");
  props.put("mail.smtp.port", "587");
  props.put("mail.smtp.auth", "true");
  props.put("mail.smtp.starttsl.enable", "true");
  session = Session.getInstance(props, null);
  output = createWriter(temp);
  output.println("Date, Time, ID, Name");
  pressedTime = millis();
  font = createFont("Hack-Regular.ttf", 16);
  cp5 = new ControlP5(this);
  cp5.addTextfield("event_name")
    .setPosition(20, 20)
    .setSize(300, 40)
    .setFont(font)
    .setText(defaultEvent)
    .setLabel("Event Name")
    .setColor(color(255, 255, 0))
    ;
  cp5.addTextfield("email_address")
    .setPosition(20, 100)
    .setSize(300, 40)
    .setFont(font)
    .setText(defaultEmail)
    .setLabel("Recipient email")
    .setColor(color(255, 255, 0))
    ;
  cp5.addBang("send_email")
    .setPosition(340, 20)
    .setSize(80, 40)
    .setLabel("Send Email")
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    ;
  cp5.addToggle("changeEmail")
    .setPosition(340, 100)
    .setSize(80, 40)
    .setLabel("Edit Details")
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    ;
  cp5.getController("changeEmail").setValue(1);
  cp5.addTextfield("name")
    .setPosition(20, 220)
    .setSize(200, 40)
    .setFont(font)
    .setColor(color(255, 255, 0))
    .setLock(true)
    ;
  cp5.addTextfield("id_number")
    .setPosition(240, 220)
    .setFont(font)
    .setSize(200, 40)
    .setColor(color(255, 255, 0))
    .setLabel("ID")
    .setLock(true)
    ;
  cp5.addTextlabel("swipes")
    .setText("swipes: 0")
    .setPosition(340, 150)
    .setFont(font)
    .setColor(color(255, 255, 0))
    ;
  cp5.addTextlabel("status")
    .setPosition(340, 65)
    .setSize(300, 40)
    .setFont(font)
    .setColor(color(255, 255, 0))
    ;
  cp5.addTextlabel("acceptingSwipes")
  //.setText("Ready to Accept Swipes")
    .setPosition(20, 190)
    .setSize(300, 40)
    .setFont(font)
    .setColor(color(255, 255, 0))
    ;

}

void draw()
{
  background(0);
  if (millis() > swipeTime + showIDtime)
  {
    cp5.get(Textfield.class, "name").clear();
    cp5.get(Textfield.class, "id_number").clear();
  }
  if (acceptSwipeFlag) cp5.get(Textlabel.class, "acceptingSwipes").setText("Ready to Accept Swipes");
  else cp5.get(Textlabel.class, "acceptingSwipes").setText("Cannot accept swipes while editing details");
  if (export)
  {
    println("saving...");
    output.flush();
    output.close();
    // is this just too hacky???
    filename = desktopPath+cp5.get(Textfield.class, "event_name").getText()+"_"+nf(hour(), 2)+nf(minute(),2)+"_"+nf(month(), 2)+"_"+nf(day(), 2)+"_"+year()+".csv";
    saveStrings(filename, loadStrings(temp));
    println("sending...");
    String subject = cp5.get(Textfield.class, "event_name").getText()+" "+month()+"/"+day()+"/"+year();
    /*
    Process p = exec("/usr/bin/mpack", "-s", message, filename, "jwmatthys@yahoo.com");
     try {
     int result = p.waitFor();
     if (result==0) println("message sent!");
     else println("the process returned " + result);
     } 
     catch (InterruptedException e) {
     }
     */
    MimeMessage message = new MimeMessage(session);
    try {
      message.setFrom(new InternetAddress("performancelab@matthysmusic.com", "Attendance Swiper"));
      String outgoingAddress = cp5.get(Textfield.class, "email_address").getText();
      message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(outgoingAddress, false));

      message.setSubject(subject);
      MimeBodyPart mbp1 = new MimeBodyPart();
      mbp1.setText("Automatically generated report attached.\n\nJoel");
      MimeBodyPart mbp2 = new MimeBodyPart();
      mbp2.attachFile(filename);
      Multipart mp = new MimeMultipart();
      mp.addBodyPart(mbp1);
      mp.addBodyPart(mbp2);
      message.setContent(mp);
      SMTPTransport t = (SMTPTransport)session.getTransport("smtp");
      t.connect("mail.gandi.net", "performancelab@matthysmusic.com", "sUz8icS3ZpVrnL");
      t.sendMessage(message, message.getAllRecipients());
      cp5.get(Textlabel.class, "status").setText("sent!");
      println("sent!");
      // reload file (to add to it)
      String[] lines = loadStrings(temp);
      try {
        temp = File.createTempFile("attendance_p5_", ".csv");
      }
      catch (Exception e)
      {
        e.printStackTrace();
        temp = new File("tempfile.csv");
      }
      output = createWriter(temp);
      for (int i = 0; i < lines.length; i++) output.println(lines[i]);
    } 
    catch (Exception e)
    {
      e.printStackTrace();
    }

    pressedTime = millis();
    export = false;
  }
}

void keyPressed()
{
  if (keyCode > 64 && digits.length() > 0 ) text += key;
  if ((keyCode == 32 || keyCode == 44) && text.length() > 0) text += " ";
  if (keyCode > 47 && keyCode < 58 && !code16)
  {
    digits += key;
  }
  if (keyCode == 10 || keyCode == 0)
  {
    String timeStamp = nf(hour(), 2)+":"+nf(minute(), 2);
    int carrollIDnumber = int(split(digits, "6298601")[0]);
    String name = text.trim();
    if (acceptSwipeFlag)
    {
      cp5.get(Textfield.class, "name").setText(name);
      cp5.get(Textfield.class, "id_number").setText(nf(carrollIDnumber));
      output.println(dateStamp+", "+timeStamp+", "+carrollIDnumber+", "+name);
      swipeTime = millis();
      text = "";
      digits = "";
      swipes++;
      cp5.get(Textlabel.class, "swipes").setText("swipes: "+swipes);
    }
  }
  code16 = (keyCode == 16);
  //TODO: Turn on LED if successful
  if (keyCode == DOWN) export = true;
  if (keyCode == ESC)
  {
    println("exiting...");
    output.flush();
    output.close();
    println("goodbye!");
    exit();
  }
}

public void send_email()
{
  cp5.get(Textlabel.class, "status").setText("sending...");
  export = true;
}

public void changeEmail (boolean theFlag)
{
  if (theFlag)
  {
    cp5.get(Textfield.class, "email_address").lock();
    cp5.get(Textfield.class, "event_name").lock();
    cp5.get(Textfield.class, "email_address").hide();
    text = "";
    digits = "";
  } else
  {
    cp5.get(Textfield.class, "email_address").unlock();
    cp5.get(Textfield.class, "event_name").unlock();
    cp5.get(Textfield.class, "email_address").show();
  }
  acceptSwipeFlag = theFlag;
}
