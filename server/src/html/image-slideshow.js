/************************************************************************************************************

Vibhu Patel - 17/08/2011

************************************************************************************************************/


	var displayWaitMessage=true;	// Display a please wait message while images are loading?


	var activeImage;
	var imageGalleryLeftPos;
	var imageGalleryWidth;
	var imageGalleryObj;
	var maxGalleryXPos;
	var slideSpeed = 0;
	var imageGalleryCaptions = new Array();
	function startSlide(e)
	{
		if(document.all)e = event;
		var id = this.id;
		this.getElementsByTagName('img')[0].src = '/style/' + this.id + '_over.gif';
		if(this.id=='arrow_right'){
			slideSpeedMultiply = Math.floor((e.clientX - this.offsetLeft) / 5);
			slideSpeed = -1*slideSpeedMultiply;
			slideSpeed = Math.max(-10,slideSpeed);
		}else if(this.id=='arrow_left'){
			slideSpeedMultiply = 10 - Math.floor((e.clientX - this.offsetLeft) / 5);
			slideSpeed = 1*slideSpeedMultiply;
			slideSpeed = Math.min(10,slideSpeed);
			if(slideSpeed<0)slideSpeed=10;
		}
	}

	function releaseSlide()
	{
		var id = this.id;
		this.getElementsByTagName('img')[0].src = '/style/' + this.id + '.gif';
		slideSpeed=0;
	}

	function gallerySlide()
	{
		if(slideSpeed!=0){
			var leftPos = imageGalleryObj.offsetLeft;
			var size = (((document.getElementById('theImages').childNodes.length * 110)+40)*-1)
			var x = document.getElementById("galleryContainer").offsetWidth;
			if( (size*-1) > x)
			{
				if(slideSpeed == -10)
				{
					if(imageGalleryObj.offsetLeft-10 > size)
					{
						imageGalleryObj.style.left = (imageGalleryObj.offsetLeft-10) + 'px';
					}
				}
				if(slideSpeed == 10)
				{
					if(imageGalleryObj.offsetLeft+10 < maxGalleryXPos)
					{
						imageGalleryObj.style.left = (imageGalleryObj.offsetLeft+10) + 'px';
					}
				}
			}
		}
		setTimeout('gallerySlide()',20);
	}

	function showImage()
	{
		if(activeImage){
			activeImage.style.filter = 'alpha(opacity=50)';
			activeImage.style.opacity = 0.5;
		}
		this.style.filter = 'alpha(opacity=140)';
		this.style.opacity = 1;
		activeImage = this;
	}

	function initSlideShow()
	{
		document.getElementById('arrow_left').onmousemove = startSlide;
		document.getElementById('arrow_left').onmouseout = releaseSlide;
		document.getElementById('arrow_right').onmousemove = startSlide;
		document.getElementById('arrow_right').onmouseout = releaseSlide;




		imageGalleryObj = document.getElementById('theImages');
		imageGalleryLeftPos = imageGalleryObj.offsetLeft;

		var galleryContainer = document.getElementById('galleryContainer');
		imageGalleryWidth = galleryContainer.offsetWidth - 80;
		maxGalleryXPos = imageGalleryObj.offsetLeft;
		minGalleryXPos = imageGalleryWidth - document.getElementById('slideEnd').offsetLeft;
		if (navigator.userAgent.indexOf('MSIE') >= 0) {
			var arrowWidth = document.getElementById('arrow_left').offsetWidth;
			var el = document.createElement('div');
			el.style.position = 'absolute';
			el.style.left = arrowWidth + 'px';
			el.style.width = (galleryContainer.offsetWidth - arrowWidth * 2) + 'px';
			el.style.overflow = 'hidden';
			el.style.height = '100%';

			document.getElementById('galleryContainer').appendChild(el);
			el.appendChild(document.getElementById('theImages'));
		}
		var slideshowImages = imageGalleryObj.getElementsByTagName('table');
		for(var no=0;no<slideshowImages.length;no++){
			slideshowImages[no].onmouseover = showImage;
		}

		//var divs = imageGalleryObj.getElementsByTagName('DIV');
		//for(var no=0;no<divs.length;no++){
		//	if(divs[no].className=='imageCaption')imageGalleryCaptions[imageGalleryCaptions.length] = divs[no].innerHTML;
		//}
		gallerySlide();
	}

	function showPreview(imagePath,imageIndex){
		var subImages = document.getElementById('previewPane').getElementsByTagName('IMG');
		if(subImages.length==0){
			var img = document.createElement('IMG');
			document.getElementById('previewPane').appendChild(img);
		}else img = subImages[0];

		if(displayWaitMessage){
			document.getElementById('waitMessage').style.display='inline';
		}
		document.getElementById('largeImageCaption').style.display='none';
		img.onload = function() { hideWaitMessageAndShowCaption(imageIndex-1); };
		img.src = imagePath;

	}
	function hideWaitMessageAndShowCaption(imageIndex)
	{
		document.getElementById('waitMessage').style.display='none';
		document.getElementById('largeImageCaption').innerHTML = imageGalleryCaptions[imageIndex];
		document.getElementById('largeImageCaption').style.display='block';

	}