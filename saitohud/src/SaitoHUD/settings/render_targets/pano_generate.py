for i in range(1, 7):
    content = """"pano_%s"
{
	"Name"		"pano_%s"
	"Width"		"2048"
	"Height"	"2048"
}""" % (i, i)
    f = open("pano_%d.txt" % i, "w")
    f.write(content)
    f.close()