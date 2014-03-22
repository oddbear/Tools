<Query Kind="Program">
  <Namespace>System.Drawing</Namespace>
</Query>

void Main()
{
	/*
	 * Check the cascade xml files and paints the features on a faceimage for easy overview.
	 */
	var root = Path.GetDirectoryName(Util.CurrentQueryPath);
	var xpath = Path.Combine(root, "haarcascade_frontalface_default.xml");
	var xml = new XmlDocument();
	xml.Load(xpath);
	
	var reg = new Regex(@"(\d+)", RegexOptions.Multiline);
	
	var colors = new List<Color>() {
		Color.Plum,
		Color.Green,
		Color.Blue,
		Color.Yellow
	};
	
	var me = Bitmap.FromFile(Path.Combine(root, "me.bmp"));
	var sb = new StringBuilder();
	//trees
	var iName = 0;
	foreach(var tree in xml.SelectNodes(@"//trees").OfType<XmlElement>())
	{
		sb.Append("<div style='border:1px solid black;margin:10px;'>");
		foreach(var elem in tree.SelectNodes(@".//rects").OfType<XmlElement>())
		{
			var children = elem.ChildNodes.OfType<XmlElement>();
			
			var image = new Bitmap(24, 24);
			var draw = Graphics.FromImage(image);
			draw.DrawImage(me, 0, 0, 24, 24);
			
			for(int i = 0; i < children.Count(); i++)
			{
				var innerText = children.ElementAt(i).InnerText;
				var s = innerText.Split(' ');
				draw.FillRectangle(new Pen(colors[i]).Brush, float.Parse(s[0]), float.Parse(s[1]), float.Parse(s[2]), float.Parse(s[3]));
			}
			
			var fileName = string.Format("{0}.bmp", iName++);
			sb.Append(string.Format("<img src='./img/{0}' style='float:left;' alt='!' />", fileName));
			WithBorder(image).Save(Path.Combine(root, "img", fileName));
		}
		sb.Append("<br style='clear:both;' />");
		sb.Append("</div>");
	}
	File.WriteAllText(Path.Combine(root, "index.html"), sb.ToString());	
}

Bitmap WithBorder(Bitmap image) {
	var newImg = new Bitmap(image.Width + 2, image.Height + 2);
	var g = Graphics.FromImage(newImg);
	
	g.DrawRectangle(new Pen(Color.Red), 0, 0, image.Width + 1, image.Height + 1);
	g.DrawImage(image, 1, 1);
	return newImg;
}