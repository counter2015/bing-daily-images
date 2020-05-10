import java.io.File
import java.net.URL


import scala.io.Source
import scala.language.postfixOps
import scala.language.implicitConversions
import scala.sys.process._


def fileDonloader(url: String, filename: String): Unit = {
  new URL(url) #> new File(filename) !!
}

val header = "https://bing.com/"

def getLink: String = {
  val src = Source.fromURL("https://bing.com")
  val lines = src.mkString
  val pattern = """(th\?id=OHR.*?jpg)""".r
  val link = pattern.findFirstIn(lines).get
  println(s"link=$link")
  link
}

val tail = getLink

val url = header + tail

val imageNameExtractPattern = ".*id=OHR\\.(.*?)_.*".r

def imageName(url: String): String = url match {
  case imageNameExtractPattern(name) => name
  case _ => "noname"
}

val filetype = ".jpg"
val folderName = "images/"
val filename = folderName + imageName(url) + filetype

fileDonloader(url, filename)
println(s"download $url to $filename")
